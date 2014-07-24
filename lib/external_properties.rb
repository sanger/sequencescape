module ExternalProperties

  def get_external_value(key)
    key = key.to_s

    # that wil load all the properties , which is faster if we access more than one property
    # and if we pre-load them with eager loaging
    external_properties.each do |property|
      return  property.value if property.key == key
    end
    return nil
  end

  def self.included(base)
    base.send(:has_many, :external_properties, :as => :propertied, :dependent => :destroy)
  end

end
