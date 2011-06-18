class ::Api::EndpointHandler < ::Core::Service
  class << self
    def instance_action(action, http_method)
      send(http_method, %r{^/#{self.api_version_path}/([\da-f]{8}(?:-[\da-f]{4}){3}-[\da-f]{12})(?:/([^/]+(?:/[^/]+)*))?$}) do
        uuid_in_url, parts = params[:captures][0], params[:captures][1].try(:split, '/') || []
        uuid = Uuid.with_external_id(uuid_in_url).first or raise ActiveRecord::RecordNotFound, "UUID does not exist"

        handle_request(:instance, action, parts) do |request|
          request.io     = ::Core::Io::Registry.instance.lookup_for_class(uuid.resource.class)
          request.target = request.io.eager_loading_for(uuid.resource.class).include_uuid.find(uuid.resource_id)
        end
      end
    end

    def model_action(action, http_method)
      send(http_method, %r{^/#{self.api_version_path}/([^\d/][^/]+(?:/[^/]+){0,2})$}) do
        parts = params[:captures].to_s.split('/')
        model = parts.shift.classify.constantize

        handle_request(:model, action, parts) do |request|
          request.io     = ::Core::Io::Registry.instance.lookup_for_class(model) rescue nil
          request.target = model
        end
      end
    end
  end

  def handle_request(handler, action, parts)
    endpoint_lookup, io_lookup =
      case handler
      when :instance then [ :endpoint_for_object, :lookup_for_object ]
      when :model    then [ :endpoint_for_class,  :lookup_for_class  ]
      else raise StandardError, "Unexpected handler #{handler.inspect}"
      end

    request = 
      ::Core::Service::Request.new do |request|
        request.service = self
        request.path    = parts
        request.json    = @json
        yield(request)
      end

    body(request.send(handler, action, send(endpoint_lookup, request.target)))
  end

  ACTIONS_TO_HTTP_VERBS = {
    :create => :post,
    :read   => :get,
    :update => :put,
    :delete => :delete
  }

  ACTIONS_TO_HTTP_VERBS.each do |action, verb|
    instance_action(action, verb)
    model_action(action, verb)
  end
end
