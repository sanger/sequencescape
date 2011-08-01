module SampleManifest::CoreBehaviour
  def self.included(base)
    base.class_eval do
      delegate :details, :validate_sample_container, :to => :core_behaviour
      attr_accessor :rapid_generation
      alias_method(:rapid_generation?, :rapid_generation)
    end
  end

  def core_behaviour
    return @core_behaviour if @core_behaviour.present?

    behaviour = case self.asset_type
    when '1dtube' then 'SampleTubeBehaviour'
    when 'plate'  then 'PlateBehaviour'
    else raise StandardError, "Unknown core behaviour (#{self.asset_type.inspect}) for sample manifest"
    end

    core = rapid_generation? ? 'RapidCore' : 'Core'
    @core_behaviour = "::SampleManifest::#{behaviour}::#{core}".constantize.new(self)
  end
  private :core_behaviour
end
