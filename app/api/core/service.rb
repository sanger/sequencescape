#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2013 Genome Research Ltd.
require 'sinatra/base'
module Core
  class Service < Sinatra::Base
    API_VERSION = 1

    class Error < StandardError
      module Behaviour
        def self.included(base)
          base.class_eval do
            class_attribute :api_error_code
            class_attribute :api_error_message
            alias_method :api_error_message, :message
            self.api_error_code = 500
          end
        end

        def api_error(response)
          response.general_error(self.class.api_error_code, [ self.class.api_error_message || self.api_error_message ])
        end
      end

      include Behaviour
    end

    class UnsupportedAction < Error
      self.api_error_code    = 501
      self.api_error_message = 'requested action is not supported on this resource'
    end

    class MethodNotAllowed < Error
      def initialize(allowed_http_verbs)
        super('HTTP verb was not allowed!')
        @allowed = Array(allowed_http_verbs).map(&:to_s).map(&:upcase).join(',')
      end

      self.api_error_code    = 405
      self.api_error_message = 'unsupported action'

      def api_error(response)
        response.headers('Allow' => @allowed)
        super
      end
    end

    # Report the performance and status of any request
    def report(handler, &block)
      Rails.logger.info("API[start]: #{handler}: #{request.fullpath}")
      yield
    ensure
      Rails.logger.info("API[handled]: #{handler}: #{request.fullpath}")
    end
    private :report

    # Disable the Sinatra rubbish that happens in the development environment because we want
    # Rails to do all of the handling if we don't
    set(:environment, Rails.env)

    # This ensures that our Sinatra applications behave properly within the Rails environment.
    # Without this you'll find that only one of the services actually behaves properly, the others
    # will all fail with 404 errors.
    def handle_not_found!(boom)
      @response.status               = 404
      @response.headers['X-Cascade'] = 'pass'
      @response.body                 = nil
    end

    # Configure a handler for the cucumber environment that logs the error to the console so that
    # we can see it.
    configure :cucumber do
      error(Exception) do
        $stderr.puts exception_thrown.message
        $stderr.puts exception_thrown.backtrace.join("\n")
        raise exception_thrown
      end
    end

    def redirect_to(url, body)
      status(301)   # Moved permanently
      headers('Location' => url)
      body(body)
    end

    def redirect_to_multiple_locations(body)
      status(300)   # Multiple content
      body(body)
    end

    def self.api_version_path
      @version = "api/#{API_VERSION}"
    end

    def api_path(*sub_path)
      "#{request.scheme}://#{request.host_with_port}/#{self.class.api_version_path}/#{sub_path.compact.join('/')}"
    end

    [ :before, :after ].each do |filter|
      line = __LINE__ + 1
      class_eval(%Q{
        def self.#{filter}_all_actions(&block)
          self.#{filter}(%r{^(/.*)?$}, &block)
        end
      }, __FILE__, line)
    end

    def command
      @command
    end

    register Core::Benchmarking
    register Core::Service::ErrorHandling
    register Core::Service::Authentication
    register Core::Service::ContentFiltering

    class Request
      extend Core::Initializable
      include Core::References
      include Core::Benchmarking
      include Core::Service::EndpointHandling

      initialized_attr_reader :service, :target, :path, :io, :json, :file, :filename
      attr_writer :io, :file, :filename
      attr_reader :ability

      delegate :user, :to => :service
      attr_reader :identifier, :started_at

      def initialize(identifier, *args, &block)
        @identifier, @started_at = identifier, Time.now
        super(*args, &block)
        @ability = Core::Abilities.create(self)
      end

      def authorisation_code
        @service.request.env['HTTP_X_SEQUENCESCAPE_CLIENT_ID']
      end

      def authentication_code
        # The WTSISignOn service has been retired. However previously the code
        # supported supplying the API key in this cookie, so this has been left
        # for compatibility purposes
        @service.request.cookies['api_key']||@service.request.cookies['WTSISignOn']
      end

      def response(&block)
        ::Core::Service::Response.new(self, &block)
      end

      # Safe way to push a particular value on to the request target stack.  Ensures that the
      # original value is reset when the block is exitted.
      def push(value, &block)
        target_before, @target = @target, value
        yield
      ensure
        @target = target_before
      end

      def attributes(object = nil)
        io.map_parameters_to_attributes(json, nil)
      end

      def create!(instance_attributes = self.attributes)
        ActiveRecord::Base.transaction do
          record = target.create!(instance_attributes)
          ::Core::Io::Registry.instance.lookup_for_object(record).eager_loading_for(record.class).include_uuid.find(record.id)
        end
      end

      def update!(instance_attributes = self.attributes(target))
        ActiveRecord::Base.transaction do
          target.tap { |o| o.update_attributes!(instance_attributes) }
        end
      end
    end

    include Core::Endpoint::BasicHandler::EndpointLookup

    # A response from an endpoint handler is made of a pair of values.  One is the object that
    # is to be sent back to the client in JSON.  The other is the endpoint handler that dealt
    # with the request and that provides the actions that are available for said object.  So
    # the JSON that is actually returned is a merge of the object JSON and the actions.
    class Response
      extend Core::Initializable
      include Core::References
      include Core::Benchmarking

      class Initializer
        delegate :status, :headers, :api_path, :to => '@owner.request.service'

        # Causes a response that will redirect the client to the specified UUID path.
        def redirect_to(uuid)
          status(301)
          headers('Location' => api_path(uuid))
        end

        # If you want to return multiple records as a kind of "redirect" then this is the
        # method you want to use!
        def multiple_choices
          status(300)
        end
      end

      attr_reader             :request
      initialized_attr_reader :handled_by, :object

      delegate :io, :identifier, :started_at, :to => :request

      delegate :status, :to => 'request.service'
      initialized_delegate :status

      delegate :endpoint_for_object, :to => 'request.service'
      private :endpoint_for_object

      def initialize(request, &block)
        @request, @io, @include_actions = request, nil, true
        status(200)
        super(&block)
      end

      #--
      # Note that this method disables garbage collection, which should improve the performance of writing
      # out the JSON to the client.  The garbage collection is then re-enabled in close.
      #++
      def each(&block)
        Rails.logger.info('API[streaming]: starting JSON streaming')
        start = Time.now

        ::Core::Io::Buffer.new(block) do |buffer|
          ::Core::Io::Json::Stream.new(buffer).open do |stream|
            ::Core::Io::Registry.instance.lookup_for_object(object).as_json(
              :response   => self,
              :target     => object,
              :stream     => stream,
              :object     => object,
              :handled_by => handled_by
            )
          end
        end

        Rails.logger.info("API[streaming]: finished JSON streaming in #{Time.now-start}s")
      end

      def close
        identifier, started_at = self.identifier, self.started_at  # Save for later as next line discards our request!
        discard_all_references
      ensure
        Rails.logger.info("API[finished]: #{identifier} in #{Time.now-started_at}s")
      end

      def discard_all_references
        request.send(:discard_all_references)
        super

        # We can also view the current connection as a reference and release that too
        ActiveRecord::Base.connection_pool.release_connection
      end
      private :discard_all_references
    end
  end
end
