# frozen_string_literal: true
module Core::Endpoint::BasicHandler::Associations::BelongsTo
  class Handler
    include Core::Endpoint::BasicHandler::EndpointLookup

    def initialize(name, options)
      @name, @options = name, options
      @throughs = Array(options[:through])
    end

    def endpoint_details(object)
      object = @throughs.inject(object) { |t, s| t.send(s) }.send(@name) || return
      yield(@options[:json].to_s, endpoint_for_object(object), object)
    rescue StandardError => e
      # We really shouldn't have an exception here, so if we do, its probably
      # an issue with configuration. We rescue and re-raise as otherwise the
      # exception and stack trace are singularly useless.
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace)
      raise StandardError, "Misconfiguration of endpoint or association: #{self}"
    end
    private :endpoint_details

    class Association
      include Core::Io::Json::Grammar::Intermediate
      include Core::Io::Json::Grammar::Resource

      def initialize(endpoint_helper, children = nil)
        super(children)
        @endpoint_helper = endpoint_helper
      end

      delegate :endpoint_details, to: :@endpoint

      def merge(node)
        super do |children|
          self.class.new(@endpoint_helper, children) # prettier-ignore
        end
      end

      def call(object, options, stream)
        @endpoint_helper.call(object) do |json_root, endpoint, associated_object|
          stream.block(json_root) do |nested_stream|
            resource_details(endpoint.instance_handler, associated_object, options, stream)
            super(object, options, nested_stream)
          end
        end
      end

      def actions(*args)
        # Nothing needed here!
      end
    end

    def separate(associations, _)
      associations[@options[:json].to_s] = Association.new(method(:endpoint_details))
    end
  end

  def initialize
    super
    @endpoints = []
  end

  def belongs_to(name, options, &)
    class_handler = Class.new(Handler).tap { |handler| self.class.const_set(name.to_s.camelize, handler) }
    @endpoints.push(class_handler.new(name, options, &))
  end

  def related
    super.concat(@endpoints)
  end
end
