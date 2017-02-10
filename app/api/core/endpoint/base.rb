# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class Core::Endpoint::Base
  module InstanceBehaviour
    class Handler < Core::Endpoint::BasicHandler
      def _read(request, _)
        yield(self, request.target)
      end
      private :_read
      standard_action(:read)
    end

    def self.extended(base)
      base.class_attribute :instance_handler, instance_writer: false
    end

    def instance(&block)
      handler = Class.new(Handler).tap { |handler| const_set(:Instance, handler) }.new(&block)
      handler.instance_variable_set(:@name, name)
      self.instance_handler = handler
    end
  end

  module ModelBehaviour
    class Handler < Core::Endpoint::BasicHandler
      include Core::Endpoint::BasicHandler::Paged

      def _read(request, _)
        request.target.order(:id).scoping do
          page    = request.path.first.try(:to_i) || 1
          results = page_of_results(request.io.eager_loading_for(request.target).include_uuid, page, request.target)
          results.singleton_class.send(:define_method, :model) { request.target }
          yield(self, results)
        end
      end
      private :_read
      standard_action(:read)
    end

    def self.extended(base)
      base.class_attribute :model_handler, instance_writer: false
    end

    def model(&block)
      handler = Class.new(Handler).tap { |handler| const_set(:Model, handler) }.new(&block)
      self.model_handler = handler
    end
  end

  extend InstanceBehaviour
  extend ModelBehaviour

  def self.root
    name.sub(/^(::)?Endpoints::/, '').underscore.pluralize
  end
end
