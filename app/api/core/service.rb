require 'sinatra/base'

class Core::Service < Sinatra::Base
  API_VERSION = 1

  class Error < StandardError
    module Behaviour
      def self.included(base)
        base.class_eval do
          class_inheritable_accessor :api_error_code
          class_inheritable_accessor :api_error_message
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
    class_eval <<-END_OF_ACTION_FILTER
      def self.#{filter}_all_actions(&block)
        self.#{filter}(%r{^/#{self.api_version_path}(/.*)?$}, &block)
      end
    END_OF_ACTION_FILTER
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
    include Core::Service::GarbageCollection::Request

    initialized_attr_reader :service, :target, :path, :io, :json
    attr_writer :io

    delegate :user, :to => :service

    def response(&block)
      ::Core::Service::Response.new(self, &block)
    end

    def authorised?
      @service.request.env['HTTP_X_SEQUENCESCAPE_CLIENT_ID'] == configatron.api.authorisation_code
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
        target.create!(instance_attributes)
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
    include Core::Service::GarbageCollection::Response

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

    delegate :io, :to => :request

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
      benchmark('Streaming JSON') do
        options = { :response => self, :uuids_to_ids => {}, :target => object }

        io_handler         = ::Core::Io::Registry.instance.lookup_for_object(object)
        object_as_json     = io_handler.as_json(options.merge(:object => object))
        actions_for_object = handled_by.as_json(options)
        merge_actions_into_object_json(object_as_json, actions_for_object)
        io_handler.post_process(object_as_json)

        Yajl::Encoder.encode(object_as_json, &block)
      end
    end

    def close
      discard_all_references
      super
    end

    def discard_all_references
      request.send(:discard_all_references)
      super

      # We can also view the current connection as a reference and release that too
      ActiveRecord::Base.connection_pool.release_connection
    end
    private :discard_all_references

    def merge_actions_into_object_json(object_as_json, actions_for_object)
      key         = object_as_json.keys.detect { |k| not [ 'uuids_to_ids', 'size' ].include?(k.to_s) }
      target_json = object_as_json[key]
      return target_json.deep_merge!(actions_for_object) unless target_json.is_a?(Array)

      # Merging the actions into a paged list of results is a little more complicated.
      # We have to remove the results from the JSON (otherwise deep_merge will overwrite
      # them) and then we have to individual merge the objects back in again.
      object_as_json.delete(key)
      object_as_json.deep_merge!(actions_for_object)
      if actions_for_object.key?(key)
        object_as_json[key] = actions_for_object[key].each_with_index.map { |oaj,i| target_json[i].deep_merge!(oaj) }
      else
        object_as_json[key] = target_json
      end
    end
    private :merge_actions_into_object_json
  end
end
