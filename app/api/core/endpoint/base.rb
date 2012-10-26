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
      base.class_inheritable_reader :instance_handler
    end

    def instance(&block)
      handler = Class.new(Handler).tap { |handler| const_set(:Instance, handler) }.new(&block)
      handler.instance_variable_set(:@name, name)
      write_inheritable_attribute(:instance_handler, handler)
    end
  end

  module ModelBehaviour
    class Handler < Core::Endpoint::BasicHandler
      include Core::Endpoint::BasicHandler::Paged

      def _read(request, _)
        request.target.send(:with_scope, :find => { :order => 'id ASC' }) do
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
      base.class_inheritable_reader :model_handler
    end

    def model(&block)
      handler = Class.new(Handler).tap { |handler| const_set(:Model, handler) }.new(&block)
      write_inheritable_attribute(:model_handler, handler)
    end
  end

  extend InstanceBehaviour
  extend ModelBehaviour

  def self.root
    self.name.sub(/^(::)?Endpoints::/, '').underscore.pluralize
  end
end
