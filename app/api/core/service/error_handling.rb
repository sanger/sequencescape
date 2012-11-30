module Core::Service::ErrorHandling
  def self.registered(app)
    app.instance_eval do
      helpers Helpers

      # We need hierarchical exception handling, so we rewrite the @errors Hash with our own implementation
      @errors = HierarchicalExceptionMap.new(@errors)

      error([ ::IllegalOperation, ::Core::Service::Error, ActiveRecord::ActiveRecordError ]) do
        buffer = [ exception_thrown.message, exception_thrown.backtrace ].join("\n")
        Rails.logger.error("API[error]: #{buffer}")

        exception_thrown.api_error(self)
      end
      error([ ::Exception ]) do
        buffer = [ exception_thrown.message, exception_thrown.backtrace ].join("\n")
        Rails.logger.error("API[error]: #{buffer}")

        self.general_error(501)
      end
    end
  end

  module Helpers
    class JsonError
      def initialize(error)
        @error = error
      end

      def each(&block)
        yield JSON.generate(@error)
        #Yajl::Encoder.new.encode(@error, &block)
      end
    end

    def exception_thrown
      @env['sinatra.error']
    end

    def general_error(code, errors = nil)
      errors ||= [ exception_thrown.message ]
      error(code, JsonError.new(:general => errors))
    end

    def content_error(code, errors = nil)
      error(code, JsonError.new(:content => errors))
    end
  end

  class HierarchicalExceptionMap < Hash
    def initialize(hash)
      super
      merge!(hash || {})
    end

    def [](key)
      return super[key] unless key.is_a?(Class)
      key = key.superclass until key.nil? or key?(key)
      super(key)
    end
  end
end

class ActiveRecord::RecordNotFound
  include ::Core::Service::Error::Behaviour
  self.api_error_code = 404
end

class ActiveRecord::AssociationTypeMismatch
  include ::Core::Service::Error::Behaviour
  self.api_error_code = 422
end

class ActiveRecord::StatementInvalid
  include ::Core::Service::Error::Behaviour
  self.api_error_code = 500
end

class ActiveRecord::ConfigurationError
  include ::Core::Service::Error::Behaviour
  self.api_error_code = 500
end

class ActiveRecord::ReadOnlyRecord
  include ::Core::Service::Error::Behaviour
  self.api_error_code = 500
end

class ActiveRecord::RecordInvalid
  def api_error(response)
    io_handler = ::Core::Io::Registry.instance.lookup_for_object(self.record)
    response.content_error(422, errors_grouped_by_attribute { |attribute| io_handler.json_field_for(attribute) })
  end

  def errors_grouped_by_attribute
    Hash[record.errors.to_a.group_by(&:first).map { |k,v| [ yield(k), v.map(&:last).uniq ] }]
  end
  private :errors_grouped_by_attribute
end

class IllegalOperation < RuntimeError
  include ::Core::Service::Error::Behaviour
  self.api_error_code    = 501
  self.api_error_message = 'requested action is not supported on this resource'
end
