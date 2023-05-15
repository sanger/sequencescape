# frozen_string_literal: true
require 'csv'
require 'yaml'

namespace :mbrave do
  desc 'Modifying tag groups'

  #
  # How to use it:
  # bundle exec rake mbrave:create_tag_plates <tag_layout_template> <login> <num_plates>
  #
  # Example:
  # bundle exec rake mbrave:create_tag_plates Bioscan_384_template_1_v3 admin 5
  task :create_tag_plates, %i[arg1 arg2] => :environment do |_t, _args|
    ActiveRecord::Base.logger.level = 2

    puts 'Creating tag plates for MBRAVE...'
    if ARGV.length != 4
      puts 'Arguments: <tag_layout_template_name> <login> <num_plates> '
      exit
    end

    _name, tag_layout_template_name, login, num_plates_str = ARGV

    num_plates = num_plates_str.to_i

    ActiveRecord::Base.transaction do
      user = User.find_by!(login: login)
      tag_layout_template = TagLayoutTemplate.find_by!(name: tag_layout_template_name)
      lot_type = LotType.find_by!(name: 'Pre Stamped Tags - 384')
      lot =
        lot_type.lots.create!(
          lot_number: "PSD_#{Time.current.to_f}",
          template: tag_layout_template,
          user: user,
          received_at: Time.current
        )

      qcc = QcableCreator.create!(lot: lot, user: user, count: num_plates)
      qcc.qcables.each_with_index do |qcable, _index|
        qcable.update!(state: 'available')
        puts " - #{qcable.asset.machine_barcode}"
      end
    end
    exit
  end

  #
  # How to use it:
  # bundle exec rake mbrave:create_tag_groups <forward_file> <reverse> <version>
  #
  # Example:
  # bundle exec rake mbrave:create_tag_groups ./forward.csv ./reverse.csv v3
  task :create_tag_groups, %i[arg1 arg2] => :environment do |_t, _args|
    # rubocop:todo Lint/ConstantDefinitionInBlock
    # rubocop:todo Metrics/AbcSize
    # rubocop:todo Metrics/MethodLength
    # Class to support creation of tag groups, tag layou templates and generation of the
    # mbrave.yml config needed by limber to be able to generate the mbrave UMI file at the
    # end of the bioscan process.
    class MbraveTagsCreator
      attr_reader :forward_filename,
                  :reverse_filename,
                  :yaml_filename,
                  :tag_identifier,
                  :version,
                  :forward_group,
                  :reverse_groups

      def initialize(params)
        @forward_filename = params[:forward_filename]
        @reverse_filename = params[:reverse_filename]
        @tag_identifier = params[:tag_identifier]
        @version = params[:version]
        @yaml_filename = params[:yaml_filename]
        @forward_group = nil
        @reverse_groups = []
      end

      def reset_yaml
        puts "Generating file #{yaml_filename}"
        File.write(yaml_filename, {}.to_yaml)
      end

      def set_yaml_for_all_environments
        contents = YAML.safe_load(File.read(yaml_filename))
        new_contents = {}
        new_contents['development'] = contents
        new_contents['test'] = contents
        new_contents['staging'] = contents
        new_contents['production'] = contents
        File.write(yaml_filename, new_contents.to_yaml)
      end

      def create_1_tag_group_forward
        tags = []
        mbrave_tags = []
        puts "Creating forward_tags from: #{forward_filename}"
        CSV.foreach(forward_filename, headers: true) do |row|
          tag = Tag.new(map_id: row['Forward Index Number'], oligo: row['F index sequence'])
          tags.push(tag)
          mbrave_tags.push(row['Forward Oligo Label'])
        end
        puts " - #{forward_tag_group_name}"
        @forward_group = _create_tag_group(forward_tag_group_name, tags)
        _add_to_yaml(yaml_filename, forward_tag_group_name, mbrave_tags, version)
      end

      def create_24_tag_groups_reverse
        tags = []
        mbrave_tags = []
        group = 1
        puts "Creating reverse tags from: #{reverse_filename}"
        CSV.foreach(reverse_filename, headers: true) do |row|
          map_id = row['Reverse Index Number'].to_i
          pos = ((map_id - 1) % 4)
          tag = Tag.new(map_id: pos, oligo: row['R index sequence'])
          tags.push(tag)
          mbrave_tags.push(row['Reverse Oligo Label'])

          if pos == 3
            puts " - #{reverse_tag_group_name(group)}"
            @reverse_groups.push(_create_tag_group(reverse_tag_group_name(group), tags))
            _add_to_yaml(yaml_filename, reverse_tag_group_name(group), mbrave_tags, version)
            group += 1
            tags = []
            mbrave_tags = []
          end
        end
      end

      def create_tag_layout_templates
        puts 'Creating tag layout templates:'
        @reverse_groups.each_with_index do |reverse_group, index|
          puts " - #{tag_layout_template_name(index)}"
          TagLayoutTemplate.create(
            name: tag_layout_template_name(index),
            tag_group: @forward_group,
            tag2_group: reverse_group,
            direction_algorithm: 'TagLayout::InColumnsThenColumns',
            walking_algorithm: 'TagLayout::Quadrants',
            enabled: true
          )
        end
      end

      def tag_layout_template_name(group)
        "#{tag_identifier}_#{group + 1}_#{version}"
      end

      def forward_tag_group_name
        "#{tag_identifier}_forward_#{version}"
      end

      def reverse_tag_group_name(group)
        "#{tag_identifier}_reverse_#{group}_#{version}"
      end

      private

      def _create_tag_group(tag_group_name, tags)
        raise "TagGroup #{tag_group_name} already exists" if TagGroup.find_by(name: tag_group_name)
        TagGroup.create(name: tag_group_name, tags: tags)
      end

      def _add_to_yaml(yaml_filename, tag_group_name, mbrave_tags, version)
        {}.tap do |obj|
          record = {}
          record['name'] = tag_group_name
          record['version'] = version
          record['tags'] = mbrave_tags

          contents = YAML.safe_load(File.read(yaml_filename))
          contents[tag_group_name] = record
          #contents.push(obj)
          File.write(yaml_filename, contents.to_yaml)
        end
      end
    end

    ActiveRecord::Base.logger.level = 2

    puts 'Creating tags for MBRAVE...'
    if ARGV.length != 4
      puts 'Arguments: <forward_tags.csv> <reverse_tags.csv> <version>'
      exit
    end

    ActiveRecord::Base.transaction do
      TAG_IDENTIFIER = 'Bioscan_384_template'
      YAML_FILENAME = 'mbrave.yml'
      _name, forward_filename, reverse_filename, version = ARGV
      mbrave_tags_creator =
        MbraveTagsCreator.new(
          forward_filename: forward_filename,
          reverse_filename: reverse_filename,
          tag_identifier: TAG_IDENTIFIER,
          version: version,
          yaml_filename: YAML_FILENAME
        )

      mbrave_tags_creator.reset_yaml
      mbrave_tags_creator.create_1_tag_group_forward
      mbrave_tags_creator.create_24_tag_groups_reverse
      mbrave_tags_creator.create_tag_layout_templates
      mbrave_tags_creator.set_yaml_for_all_environments
      
    end

    # rubocop:enable Lint/ConstantDefinitionInBlock
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    exit
  end
end
