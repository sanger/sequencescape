class ResourceProxy
  def initialize(resource, resource_class)
    @resource_id = case resource
                  when String
                    resource
                  when Integer
                    resource
                  when Hash
                    resource["id"]  #|| resource[:id]
                  when NilClass
                    nil
                  else
                    @object = resource
                    resource.id
                  end
    @resource_class = resource_class
  end

  def id
    @resource_id
  end

  def object
    @object ||= @resource_class.find(@resource_id)
  end

  def set_object(object)
    @object = object
  end

  def loaded?
    @object ? true : false
  end
end
