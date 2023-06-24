# frozen_string_literal: true
require 'csv'
require 'yaml'

TAG_IDENTIFIER = 'Bioscan'

namespace :mbrave do
  desc 'MBRAVE generation related tasks'

  #
  # How to use it:
  # bundle exec rake 'mbrave:create_tag_plates[<login>,<version>]'
  #
  # Example:
  # bundle exec rake 'mbrave:create_tag_plates[admin,v1]'
  task :create_tag_plates, %i[login version] => :environment do |_t, args|
    ActiveRecord::Base.logger.level = 2

    def text_code_for_tag_layout(tag_layout_template)
      mreg = tag_layout_template.name.match(Regexp.new('^Bioscan_384_template_(\\d+)_'))
      "T#{mreg[1]}"
    end

    # rubocop:todo Metrics/AbcSize
    def create_tag_plates(tag_layout_templates, user)
      ActiveRecord::Base.transaction do
        lot_type = LotType.find_by!(name: 'Pre Stamped Tags - 384')
        tag_layout_templates.each_with_index do |tag_layout_template, _index|
          lot =
            lot_type.lots.create!(
              lot_number: "PSD_#{Time.current.to_f}",
              template: tag_layout_template,
              user: user,
              received_at: Time.current
            )
          text_code = text_code_for_tag_layout(tag_layout_template)
          barcode = PlateBarcode.create_barcode_with_text(text_code)

          qcc = QcableCreator.create!(lot: lot, user: user, supplied_barcode: barcode)
          qcc.qcables.each_with_index do |qcable, _index|
            qcable.update!(state: 'available')
            puts "#{tag_layout_template.name}:"
            puts " - #{barcode}"
          end
        end
      end
    end

    # rubocop:enable Metrics/AbcSize

    puts 'Creating tag plates for MBRAVE...'
    if args.to_hash.keys.length != 2
      puts 'Arguments: <login> <version> '
      next
    end

    user = User.find_by!(login: args[:login])
    version = args[:version]

    tag_layout_templates =
      TagLayoutTemplate.all.select do |template|
        template.name.match(Regexp.new("^Bioscan_384_template_(\\d+)_#{version}$"))
      end

    create_tag_plates(tag_layout_templates, user)
  end

  #
  # How to use it:
  # bundle exec rake 'mbrave:create_tag_groups[<forward_tags.csv>,<reverse_tags.csv>,<version>]'
  #
  # Example:
  # bundle exec rake 'mbrave:create_tag_groups[./forward.csv,./reverse.csv,v3]'
  task :create_tag_groups, %i[forward_file reverse_file version] => :environment do |_t, args|
    # rubocop:todo Lint/ConstantDefinitionInBlock
    # rubocop:todo Metrics/AbcSize
    # rubocop:todo Metrics/MethodLength
    # Class to support creation of tag groups, tag layout templates and generation of the
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
        @yaml_contents = {}
      end

      def write_yaml(yaml_filename)
        puts "Generating file #{yaml_filename}"
        new_contents = {}
        new_contents['development'] = @yaml_contents
        new_contents['test'] = @yaml_contents
        new_contents['staging'] = @yaml_contents
        new_contents['training'] = @yaml_contents
        new_contents['production'] = @yaml_contents
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
        _add_to_yaml(yaml_filename, forward_tag_group_name, mbrave_tags, version, 1)
      end

      def create_24_tag_groups_reverse
        tags = []
        mbrave_tags = []
        group = 1
        puts "Creating reverse tags from: #{reverse_filename}"
        CSV.foreach(reverse_filename, headers: true) do |row|
          _validate_reverse_row(row)
          map_id = row['Reverse Index Number'].to_i
          pos = ((map_id - 1) % 4)
          tag = Tag.new(map_id: pos, oligo: row['R index sequence'])
          tags.push(tag)
          mbrave_tags.push(row['Reverse Oligo Label'])

          if pos == 3
            puts " - #{reverse_tag_group_name(group)}"
            @reverse_groups.push(_create_tag_group(reverse_tag_group_name(group), tags))
            _add_to_yaml(yaml_filename, reverse_tag_group_name(group), mbrave_tags, version, group)
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
        "#{tag_identifier}_384_template_#{group + 1}_#{version}"
      end

      def forward_tag_group_name
        "#{tag_identifier}_forward_96_#{version}"
      end

      def reverse_tag_group_name(group)
        "#{tag_identifier}_reverse_4_#{group}_#{version}"
      end

      private

      def _validate_reverse_row(row)
        ['Reverse Index Number', 'R index sequence', 'Reverse Oligo Label'].each do |header|
          raise "Could not find header #{header}" unless row.include?(header)
        end
      end

      def _create_tag_group(tag_group_name, tags)
        raise "TagGroup #{tag_group_name} already exists" if TagGroup.find_by(name: tag_group_name)
        TagGroup.create(name: tag_group_name, tags: tags)
      end

      def _add_to_yaml(_yaml_filename, tag_group_name, mbrave_tags, version, num_plate)
        record = {}
        record['name'] = tag_group_name
        record['version'] = version
        record['num_plate'] = num_plate
        record['tags'] = mbrave_tags

        @yaml_contents[tag_group_name] = record
      end
    end

    ActiveRecord::Base.logger.level = 2

    puts 'Creating tags for MBRAVE...'
    if args.to_hash.keys.length != 3
      puts 'Invalid arguments. Call should be:'
      puts 'rake \'mbrave:create_tag_groups[<forward_tags.csv>,<reverse_tags.csv>,<version>]\''
      next
    end

    ActiveRecord::Base.transaction do
      YAML_FILENAME = 'mbrave.yml'

      mbrave_tags_creator =
        MbraveTagsCreator.new(
          forward_filename: args[:forward_file],
          reverse_filename: args[:reverse_file],
          tag_identifier: TAG_IDENTIFIER,
          version: args[:version],
          yaml_filename: YAML_FILENAME
        )

      mbrave_tags_creator.create_1_tag_group_forward
      mbrave_tags_creator.create_24_tag_groups_reverse
      mbrave_tags_creator.create_tag_layout_templates
      mbrave_tags_creator.write_yaml(YAML_FILENAME)
    end

    # rubocop:enable Lint/ConstantDefinitionInBlock
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    next
  end
end
