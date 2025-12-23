# frozen_string_literal: true
module SampleManifest::CoreBehaviour
  BEHAVIOURS = %w[1dtube plate multiplexed_library library library_plate tube_rack].freeze

  # Include in cores which exhibit the default behaviour
  module NoSpecializedValidation
    def validate_specialized_fields(*args)
    end

    def specialized_fields(*_args)
      {}
    end
  end

  module Shared
    def self.included(base)
      base.class_eval do
        delegate :create_sample, to: :@manifest
        delegate :samples, :sample_manifest_assets, :barcodes, :study, to: :@manifest
        delegate :count, to: :@manifest
        delegate :study, to: :@manifest
        delegate :purpose, to: :@manifest
      end
    end

    def generate_sanger_ids(count = 1)
      Array.new(count) { SangerSampleId::Factory.instance.next! }
    end

    def details(&)
      details_array.each(&)
    end
  end

  # The samples get registered in the stock resource table at the end of manifest upload and processing
  # (It used to happen here)
  module StockAssets
    # Used in manifest upload code to insert the sample and aliquot into the database.
    # The receptacle and sanger_sample_id already exist as they are inserted upfront when the manifest is generated.
    # tag_depth is set on the aliquot to avoid tag clash if a) pools are present, and b) if the samples are not tagged.
    # The assumption is made that samples passed to the below method are never tagged,
    # because we're in the 'StockAssets' module rather than the 'LibraryAssets' module.
    def generate_sample_and_aliquot(sanger_sample_id, receptacle)
      create_sample(sanger_sample_id).tap do |sample|
        tag_depth = tag_depth_for_sample(@manifest.pools, receptacle, sanger_sample_id)

        receptacle.aliquots.create!(sample:, study:, tag_depth:)

        study.samples << sample
      end
    end

    def stocks?
      true
    end

    # Assigns a tag_depth to a sample in a pool.
    # Tag_depth just needs to be a unique integer for each sample in the pool,
    # So we just use the index in the list of sample manifest assets in this receptacle.
    def tag_depth_for_sample(pools, receptacle, sanger_sample_id)
      return nil unless pools

      pools[receptacle].find_index { |sma| sma.sanger_sample_id == sanger_sample_id }
    end
  end

  # Used for ready-made libraries. Ensures that the library_id gets set
  module LibraryAssets
    def generate_sample_and_aliquot(sanger_sample_id, receptacle)
      create_sample(sanger_sample_id).tap do |sample|
        receptacle.aliquots.create!(sample: sample, study: study, library: receptacle)
        study.samples << sample
      end
    end

    def stocks?
      true
    end

    def labware_type
      asset_type == 'well' ? 'library_plate_well' : 'library_tube'
    end
  end

  def self.included(base)
    base.class_eval do
      delegate :details, :details_array, :validate_specialized_fields, :specialized_fields, to: :core_behaviour

      def self.supported_asset_type?(asset_type)
        asset_type.nil? || BEHAVIOURS.include?(asset_type)
      end
    end
  end

  def core_behaviour
    @core_behaviour ||= "::SampleManifest::#{behaviour_module}::Core".constantize.new(self)
  end

  private

  # rubocop:todo Metrics/MethodLength
  def behaviour_module # rubocop:todo Metrics/CyclomaticComplexity
    case asset_type
    when '1dtube'
      'SampleTubeBehaviour'
    when 'plate'
      'PlateBehaviour'
    when 'tube_rack'
      'TubeRackBehaviour'
    when 'multiplexed_library'
      'MultiplexedLibraryBehaviour'
    when 'library'
      'LibraryTubeBehaviour'
    when 'library_plate'
      'LibraryPlateBehaviour'
    when nil
      'UnspecifiedBehaviour'
    else
      raise StandardError, "Unknown core behaviour (#{asset_type.inspect}) for sample manifest"
    end
  end
  # rubocop:enable Metrics/MethodLength
end
