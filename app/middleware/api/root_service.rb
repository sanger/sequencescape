#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
# require './app/api/core/service'
module Api
  class RootService < ::Core::Service
    # NOTE: This is partly a hack but it suffices to keep the dynamic ability to write endpoints.
    ALL_SERVICES_AVAILABLE = Hash[Dir.glob(File.join(Rails.root, %w{app api endpoints ** *.rb})).map do |file|
      handler = file.gsub(%r{^.+/(endpoints/.+).rb$}, '\1').camelize.constantize
      [ handler.root.gsub('/', '_'), handler ]
    end]

    use Api::EndpointHandler

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
                    ).map do |action,url|
                      actions_stream.attribute(action,url)
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
    get(%r{^/?$}) do
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
      send(action, %r{^/?$}) do
        raise MethodNotAllowed, [ :get ]
      end
    end
  end
end
