# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

module SampleManifest::MultiplexedLibraryBehaviour
  module ClassMethods
    def create_for_multiplexed_library!(attributes, *args, &block)
      create!(attributes.merge(asset_type: 'multiplexed_library'), *args, &block).tap do |manifest|
        manifest.generate
      end
    end
  end

  class Core
    # for #multiplexed_library_tube
    MxLibraryTubeException = Class.new(ActiveRecord::RecordNotFound)

    def initialize(manifest)
      @manifest = manifest
    end

    delegate :generate_mx_library, to: :@manifest

    def generate
      @mx_tube = generate_mx_library
    end

    delegate :samples, to: :@manifest

    def io_samples
      samples.map do |sample|
        {
          sample: sample,
          container: {
            barcode: sample.primary_receptacle.sanger_human_barcode
          },
          library_information: sample.primary_receptacle.library_information
        }
      end
    end

    def multiplexed_library_tube
      @mx_tube || raise(MxLibraryTubeException.new, 'Mx tube not found')
    end

    def printables
      multiplexed_library_tube
    end

    def updated_by!(user, samples)
      # Does nothing at the moment
    end

    def details
      samples.each do |sample|
        yield({
          barcode: sample.assets.first.sanger_human_barcode,
          sample_id: sample.sanger_sample_id
        })
      end
    end

    def details_array
      [].tap do |details|
        samples.each do |sample|
          details << {
            barcode: sample.assets.first.sanger_human_barcode,
            sample_id: sample.sanger_sample_id
          }
        end
      end
    end

    def validate_sample_container(sample, row)
      manifest_barcode, primary_barcode = row['SANGER TUBE ID'], sample.primary_receptacle.sanger_human_barcode
      return if primary_barcode == manifest_barcode
      yield("You can not move samples between tubes. #{sample.sanger_sample_id} is supposed to be in '#{primary_barcode}'' but has been moved to '#{manifest_barcode}'.")
    end

    def required_fields
      ['TAG INDEX', 'LIBRARY TYPE', 'INSERT SIZE FROM', 'INSERT SIZE TO']
    end

    def numeric_fields
      ['INSERT SIZE FROM', 'INSERT SIZE TO']
    end

    # Chances are we're going to use the same tag group multiple times. This avoids the need to poll
    # the database each time, allowing us just to retrieve the list of tags in one go.
    def tag_group_cache(name)
      @tag_group_cache ||= Hash.new { |h, new_name| h[new_name] = TagGroup.include_tags.find_by(name: new_name) }
      @tag_group_cache[name]
    end

    # There are a lot of things that can go wrong here
    def validate_specialized_fields(sample, row)
      required_fields.each do |field|
        yield  "#{sample.sanger_sample_id} has no #{field.downcase} specified." if row[field].blank?
      end

      numeric_fields.each do |field|
        yield  "#{sample.sanger_sample_id} #{field.downcase} should be a number." unless /^[0-9]+$/ === row[field].strip
        yield  "#{sample.sanger_sample_id} #{field.downcase} should be greater than 0." unless row[field].to_i > 0
      end

      yield "Couldn't find the library type #{row['LIBRARY TYPE']} for #{sample.sanger_sample_id}." if LibraryType.find_by(name: row['LIBRARY TYPE']).nil?

      return yield "#{sample.sanger_sample_id} has no tag group specified." if row[SampleManifest::Headers::TAG_GROUP_FIELD].blank?

      # Tag Group validation
      tag_group = tag_group_cache(row[SampleManifest::Headers::TAG_GROUP_FIELD])
      return yield "Couldn't find a tag group called '#{row[SampleManifest::Headers::TAG_GROUP_FIELD]}'" if tag_group.nil?
      yield "#{tag_group.name} doesn't include a tag with index #{row['TAG INDEX']}" if tag_group.tags.detect { |tag| tag.map_id == row['TAG INDEX'].to_i }.nil?

      # Keep track if our first row is dual indexed or not.
      @dual_indexed = row[SampleManifest::Headers::TAG2_GROUP_FIELD].present? if @dual_indexed.nil?
      return yield 'All samples in pool must have the same number of tags' unless @dual_indexed == row[SampleManifest::Headers::TAG2_GROUP_FIELD].present?
      return unless @dual_indexed

      tag2_group = tag_group_cache(row[SampleManifest::Headers::TAG2_GROUP_FIELD])
      return yield "Couldn't find a tag group called '#{row[SampleManifest::Headers::TAG_GROUP_FIELD]}' for tag 2" if tag2_group.nil?
      yield "#{tag2_group.name} doesn't include a tag with index #{row[SampleManifest::Headers::TAG2_INDEX_FIELD]}" if tag2_group.tags.detect { |tag| tag.map_id == row[SampleManifest::Headers::TAG2_INDEX_FIELD].to_i }.nil?
    end

    def specialized_fields(row)
      tag_group = tag_group_cache(row[SampleManifest::Headers::TAG_GROUP_FIELD])

      {
        specialized_from_manifest: {
          tag_id: tag_group.tags.detect { |tag| tag.map_id == row['TAG INDEX'].to_i }.id,
          library_type: row['LIBRARY TYPE'],
          insert_size_from: row['INSERT SIZE FROM'].to_i,
          insert_size_to: row['INSERT SIZE TO'].to_i
        }
      }.tap do |params|
        if row[SampleManifest::Headers::TAG2_GROUP_FIELD].present?
          tag2_group = tag_group_cache(row[SampleManifest::Headers::TAG2_GROUP_FIELD])
          params[:specialized_from_manifest].merge!(tag2_id: tag2_group.tags.detect { |tag| tag.map_id == row[SampleManifest::Headers::TAG2_INDEX_FIELD].to_i }.id)
        end
      end
    end
  end

  RapidCore = Core

  def self.included(base)
    base.class_eval do
      extend ClassMethods
    end
  end

  def generate_mx_library
    tubes = generate_tubes(Tube::Purpose.standard_library_tube)
    Tube::Purpose.standard_mx_tube.create!.tap do |mx_tube|
      RequestFactory.create_external_multiplexed_library_creation_requests(tubes, mx_tube, study)
    end
  end

  def sample_tube_sample_creation(samples_data, _study_id)
    study.samples << samples_data.map do |barcode, sanger_sample_id, _prefix|
      create_sample(sanger_sample_id).tap do |sample|
        sample_tube = LibraryTube.find_by(barcode: barcode) or raise ActiveRecord::RecordNotFound, "Cannot find library tube with barcode #{barcode.inspect}"
        sample_tube.aliquots.create!(sample: sample)
      end
    end
  end
  private :sample_tube_sample_creation
end
