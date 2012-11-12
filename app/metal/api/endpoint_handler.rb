class ::Api::EndpointHandler < ::Core::Service
  class << self
    def instance_action(action, http_method)
      send(http_method, %r{^/#{self.api_version_path}/([\da-f]{8}(?:-[\da-f]{4}){3}-[\da-f]{12})(?:/([^/]+(?:/[^/]+)*))?$}) do
        report("instance") do
          uuid_in_url, parts = params[:captures][0], params[:captures][1].try(:split, '/') || []
          uuid = Uuid.with_external_id(uuid_in_url).first or raise ActiveRecord::RecordNotFound, "UUID does not exist"

          handle_request(:instance, request, action, parts) do |request|
            request.io     = lookup_for_class(uuid.resource.class) { |e| raise e }
            request.target = request.io.eager_loading_for(uuid.resource.class).include_uuid.find(uuid.resource_id)
          end
        end
      end
    end

    def model_action(action, http_method)
      send(http_method, %r{^/#{self.api_version_path}/([^\d/][^/]+(?:/[^/]+){0,2})$}) do
        report("model") do
          determine_model_from_parts(*params[:captures].to_s.split('/')) do |model, parts|
            handle_request(:model, request, action, parts) do |request|
              request.io     = lookup_for_class(model) { |_| nil }
              request.target = model
            end
          end
        end
      end
    end
  end

  def lookup_for_class(model, &block)
    ::Core::Io::Registry.instance.lookup_for_class(model)
  rescue ::Core::Registry::UnregisteredError => exception
    block.call(exception)
  end
  private :lookup_for_class

  # Report the performance and status of any request
  def report(handler, &block)
    start = Time.now
    Rails.logger.info("API[start]: #{handler}: #{request.fullpath}")
    yield
  ensure
    Rails.logger.info("API[handled]: #{handler}: #{request.fullpath} in #{Time.now-start}s")
  end
  private :report

  # Not ideal but at least this allows us to pick up the appropriate model from the URL.
  def determine_model_from_parts(*parts)
    (1..parts.length).to_a.reverse.each do |n|
      begin
        model_name, remainder = parts.slice(0, n), parts.slice(n, parts.length)
        return yield(model_name.join('/').classify.constantize, remainder)
      rescue NameError => exception
        # Nope, try again
      end
    end
    raise StandardError, "Cannot route #{parts.join('/').inspect}"
  end
  private :determine_model_from_parts

  def handle_request(handler, http_request, action, parts)
    endpoint_lookup, io_lookup =
      case handler
      when :instance then [ :endpoint_for_object, :lookup_for_object ]
      when :model    then [ :endpoint_for_class,  :lookup_for_class  ]
      else raise StandardError, "Unexpected handler #{handler.inspect}"
      end

    request = 
      ::Core::Service::Request.new(requested_url = http_request.fullpath) do |request|
        request.service = self
        request.path    = parts
        request.json    = @json
        yield(request)
      end

    endpoint = send(endpoint_lookup, request.target)
    Rails.logger.info("API[endpoint]: #{handler}: #{requested_url} handled by #{endpoint.inspect}")
    body(request.send(handler, action, endpoint))
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
