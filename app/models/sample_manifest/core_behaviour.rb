module SampleManifest::CoreBehaviour
  # Include in cores which exhibit the default behaviour
  module NoSpecializedValidation
    def validate_specialized_fields(*args); end

    def specialized_fields(*_args); {}; end
  end

  def self.included(base)
    base.class_eval do
      delegate :details, :details_array, :validate_specialized_fields, :specialized_fields, to: :core_behaviour

      def self.supported_asset_type?(asset_type)
        asset_type.nil? || %w(1dtube plate multiplexed_library library).include?(asset_type)
      end
    end
  end

  private

  def core_behaviour
    @core_behaviour ||= "::SampleManifest::#{behaviour_module}::Core".constantize.new(self)
  end

  def behaviour_module
    case asset_type
    when '1dtube'              then 'SampleTubeBehaviour'
    when 'plate'               then 'PlateBehaviour'
    when 'multiplexed_library' then 'MultiplexedLibraryBehaviour'
    when 'library'             then 'LibraryBehaviour'
    when nil                   then 'UnspecifiedBehaviour'
    else raise StandardError, "Unknown core behaviour (#{asset_type.inspect}) for sample manifest"
    end
  end
end
