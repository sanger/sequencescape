module SampleManifest::CoreBehaviour
  BEHAVIOURS = %w[1dtube plate multiplexed_library library library_plate tube_rack].freeze

  # Include in cores which exhibit the default behaviour
  module NoSpecializedValidation
    def validate_specialized_fields(*args); end

    def specialized_fields(*_args); {}; end
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

    def details(&block)
      details_array.each(&block)
    end
  end

  module StockAssets
    def generate_sample_and_aliquot(sanger_sample_id, receptacle)
      create_sample(sanger_sample_id).tap do |sample|
        receptacle.aliquots.create!(sample: sample, study: study)
        receptacle.register_stock!
        study.samples << sample
      end
    end
  end

  module LibraryAssets
    def generate_sample_and_aliquot(sanger_sample_id, receptacle)
      create_sample(sanger_sample_id).tap do |sample|
        receptacle.aliquots.create!(sample: sample, study: study, library: receptacle)
        study.samples << sample
      end
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

  def behaviour_module
    case asset_type
    when '1dtube'              then 'SampleTubeBehaviour'
    when 'plate'               then 'PlateBehaviour'
    when 'tube_rack'           then 'TubeRackBehaviour'
    when 'multiplexed_library' then 'MultiplexedLibraryBehaviour'
    when 'library'             then 'LibraryTubeBehaviour'
    when 'library_plate'       then 'LibraryPlateBehaviour'
    when nil                   then 'UnspecifiedBehaviour'
    else raise StandardError, "Unknown core behaviour (#{asset_type.inspect}) for sample manifest"
    end
  end
end
