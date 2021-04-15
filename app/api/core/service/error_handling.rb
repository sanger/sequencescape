module Core::Service::ErrorHandling # rubocop:todo Style/Documentation
  def self.registered(app)
    app.instance_eval do
      helpers Helpers

      error(
        ::IllegalOperation,
        ::Core::Service::Error,
        ActiveRecord::ActiveRecordError,
        ActiveModel::ValidationError,
        Aliquot::TagClash
      ) do
        buffer = [exception_thrown.message, exception_thrown.backtrace].join("\n")
        Rails.logger.error("API[error]: #{buffer}")
        exception_thrown.api_error(self)
      end
      error(StandardError) do
        buffer = [exception_thrown.message, exception_thrown.backtrace].join("\n")
        Rails.logger.error("API[error]: #{buffer}")
        general_error(501)
      end
    end
  end

  module Helpers # rubocop:todo Style/Documentation
    class JsonError # rubocop:todo Style/Documentation
      def initialize(error)
        @error = error
      end

      def each
        yield JSON.generate(@error)
      end
    end

    def exception_thrown
      @env['sinatra.error']
    end

    def general_error(code, errors = nil)
      Rails.logger.error(exception_thrown.backtrace.join("\n"))
      errors ||= [exception_thrown.message]
      error(code, JsonError.new(general: errors))
    end

    def content_error(code, errors = nil)
      error(code, JsonError.new(content: errors))
    end
  end
end

class ActiveRecord::ActiveRecordError # rubocop:todo Style/Documentation
  include ::Core::Service::Error::Behaviour
  self.api_error_code = 500
end

class ActiveRecord::RecordNotFound # rubocop:todo Style/Documentation
  self.api_error_code = 404
end

class ActiveRecord::AssociationTypeMismatch # rubocop:todo Style/Documentation
  self.api_error_code = 422
end

class ActiveRecord::RecordInvalid # rubocop:todo Style/Documentation
  def api_error(response)
    io_handler = ::Core::Io::Registry.instance.lookup_for_object(record)
    response.content_error(422, errors_grouped_by_attribute { |attribute| io_handler.json_field_for(attribute) })
  end

  def errors_grouped_by_attribute
    record.errors.map { |k, v| [yield(k), [v].flatten.uniq] }.to_h
  end
  private :errors_grouped_by_attribute
end

class ActiveModel::ValidationError # rubocop:todo Style/Documentation
  def api_error(response)
    io_handler = ::Core::Io::Registry.instance.lookup_for_object(model)
    response.content_error(422, errors_grouped_by_attribute { |attribute| io_handler.json_field_for(attribute) })
  end

  def errors_grouped_by_attribute
    model.errors.map { |k, v| [yield(k), [v].flatten.uniq] }.to_h
  end
  private :errors_grouped_by_attribute
end

class ActiveRecord::RecordNotSaved # rubocop:todo Style/Documentation
  def api_error(response)
    response.content_error(422, message)
  end
end

class IllegalOperation < RuntimeError # rubocop:todo Style/Documentation
  include ::Core::Service::Error::Behaviour
  self.api_error_code    = 501
  self.api_error_message = 'requested action is not supported on this resource'
end

Aliquot::TagClash.include ::Core::Service::Error::Behaviour
Aliquot::TagClash.api_error_code = 422
