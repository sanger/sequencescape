class Api::RootService < ::Core::Service
  # NOTE: This is partly a hack but it suffices to keep the dynamic ability to write endpoints.
  ALL_SERVICES_AVAILABLE = Hash[Dir.glob(File.join(Rails.root, %w{app api endpoints *.rb})).map do |file|
    handler = file.gsub(%r{^.+/(endpoints/.+).rb$}, '\1').camelize.constantize
    [ handler.root, handler ]
  end]

  module RootResponse
    def services(services)
      self.object = services

      def @owner.each(&block)
        json = Hash[
          object.map do |model_in_json,endpoint|
            [model_in_json, endpoint.model_handler.as_json(:response => self, :endpoint => endpoint, :target => endpoint.model_handler)]
          end +
          [ [ 'revision', 2 ] ]
        ]
        Yajl::Encoder.new.encode(json, &block)
      end
    end
  end

  # It appears that if you go through a service like nginx or mongrel cluster(?) that the trailing
  # slash gets stripped off any requests, so we have to account for that with the root actions.
  get(%r{^/#{self.api_version_path}/?$}) do
    result = report("root") do
      ::Core::Service::Request.new(request.fullpath) do |request|
        request.service = self
        request.path    = '/'
      end.response do |response|
        class << response ; include RootResponse ; end
        response.services(ALL_SERVICES_AVAILABLE)
      end
    end

    body(result)
  end

  [ :post, :put, :delete ].each do |action|
    send(action, %r{^/#{self.api_version_path}/?$}) do
      raise MethodNotAllowed, [ :get ]
    end
  end
end
