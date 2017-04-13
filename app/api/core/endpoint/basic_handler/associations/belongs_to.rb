# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

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
        super(node) { |children| self.class.new(@endpoint_helper, children) }
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

  def belongs_to(name, options, &block)
    class_handler = Class.new(Handler).tap { |handler| self.class.const_set(name.to_s.camelize, handler) }
    @endpoints.push(class_handler.new(name, options, &block))
  end

  def related
    super.concat(@endpoints)
  end
end
