# {include:file:docs/api_v1.md}
module Api
  # Sinatra application which provides routing for the V1 API
  # Automatically generates routes from the files listed under `app/api/endpoints`
  # This particular class handles the actual root response, other endpoints are
  # handled by {Api::EndpointHandler}
  class RootService < ::Core::Service
    # @note This is partly a hack but it suffices to keep the dynamic ability to write endpoints.
    ALL_SERVICES_AVAILABLE = Dir.glob(File.join(Rails.root, %w{app api endpoints ** *.rb})).map do |file|
      handler = file.gsub(%r{^.+/(endpoints/.+).rb$}, '\1').camelize.constantize
      [handler.root.tr('/', '_'), handler]
    end.to_h

    use Api::EndpointHandler

    module RootResponse # rubocop:todo Style/Documentation
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
                      response: self, endpoint: endpoint
                    ).map do |action, url|
                      actions_stream.attribute(action, url)
                    end
                  end
                end
              end
            end
          end
          # json = Hash[
          #   object.map do |model_in_json,endpoint|
          #     [model_in_json, endpoint.model_handler.as_json(:response => self, :endpoint => endpoint, :target => endpoint.model_handler)]
          #   end +
          #   [ [ 'revision', 2 ] ]
          # ]
          # #Yajl::Encoder.new.encode(json, &block)
          # yield JSON.generate(json)
        end
      end
    end

    # It appears that if you go through a service like nginx or mongrel cluster(?) that the trailing
    # slash gets stripped off any requests, so we have to account for that with the root actions.
    get(%r{/?}) do
      result = report('root') do
        ::Core::Service::Request.new(request.fullpath) do |request|
          request.service = self
          request.path    = '/'
        end.response do |response|
          class << response; include RootResponse; end
          response.services(ALL_SERVICES_AVAILABLE)
        end
      end

      body(result)
    end

    %i[post put delete].each do |action|
      send(action, %r{/?}) do
        raise MethodNotAllowed, [:get]
      end
    end
  end
end
