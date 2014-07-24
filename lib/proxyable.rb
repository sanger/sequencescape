# Mixin providing interface to proxy creation and proxy support.
module Proxyable
  def self.included(base)
    base.extend ClassMethods
  end

  def proxy
    unless @proxy
      @proxy = self.class.new_proxy(self)
    end

    @proxy
  end

  # Class Methods for the mixed class
  module ClassMethods
    # defines the proxy class. Override to use a specific customized ResourceProxy
    # Note than there is another mechanism to define specific for a nested resource
    # @return (Class<=ResourceProxy)
    def proxy_class
      ResourceProxy
    end

    def new_proxy_list(object_list = [])
      object_list.map { |o| new_proxy(o) }
    end

    # Create a new proxy for an object from partial description of it.
    # @param [String, Integer, Object] object
    # @return ResourceProxy
    def new_proxy(object)
      proxy_class.new(object, self)
    end

    # This method load all object from a proxy list. Skip it if the first object is already loaded
    def load_proxy_list(proxy_list, options = {})
      return if proxy_list.empty?

      force = options.delete(:force)
      return if proxy_list.first.loaded? && ( ! force )

      ids_to_proxies = proxy_list.index_by(&:id)
      results = self.find(ids_to_proxies.keys, options)
      results.each { |object| ids_to_proxies[ object.id ].set_object(object) }
      results
    end
  end
end
