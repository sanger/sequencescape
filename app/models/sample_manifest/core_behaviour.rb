module SampleManifest::CoreBehaviour
  def self.included(base)
    base.delegate :details, :to => :core_behaviour
  end

  def core_behaviour
    @core_behaviour = case self.asset_type
    when '1dtube' then ::SampleManifest::SampleTubeBehaviour::Core.new(self)
    when 'plate'  then ::SampleManifest::PlateBehaviour::Core.new(self)
    else raise StandardError, "Unknown core behaviour (#{self.asset_type.inspect}) for sample manifest"
    end
  end
  private :core_behaviour
end
