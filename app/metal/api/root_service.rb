class Api::RootService < ::Core::Service
  # NOTE: This is partly a hack but it suffices to keep the dynamic ability to write endpoints.
  ALL_SERVICES_AVAILABLE = Hash[Dir.glob(File.join(Rails.root, %w{app api endpoints ** *.rb})).map do |file|
    handler = file.gsub(%r{^.+/(endpoints/.+).rb$}, '\1').camelize.constantize
    [ handler.root.gsub('/', '_'), handler ]
  end]

  module RootResponse
    def services(services)
      self.object = services

      def @owner.each(&block)
        ::Core::Io::Buffer.new(block) do |buffer|
          ::Core::Io::Json::Stream.new(buffer).open do |stream|
            stream.attribute('revision', 2)
            object.each do |model_in_json, endpoint|
              stream.block(model_in_json) do |nested_stream|
                nested_stream.block('actions') do |actions_stream|
                  endpoint.model_handler.send(
                    :actions,
                    endpoint.model_handler,
                    :response => self, :endpoint => endpoint
                  ).map(&actions_stream.method(:attribute))
                end
              end
            end
          end
        end
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
