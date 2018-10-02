module Core::Service::EndpointHandling
  def self.included(base)
    base.class_eval do
      attr_reader :endpoint
    end
  end

  def instance(action, endpoint)
    @endpoint = endpoint
    @endpoint.instance_handler.send(action, self, path)
  end

  def model(action, endpoint)
    @endpoint = endpoint
    @endpoint.model_handler.send(action, self, path)
  end
end
