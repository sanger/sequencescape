# frozen_string_literal: true
module Core::Service::ErrorHandling
  def self.registered(app) # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
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

  module Helpers
    class JsonError
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

class ActiveRecord::ActiveRecordError
  include ::Core::Service::Error::Behaviour

  self.api_error_code = 500
end

class ActiveRecord::RecordNotFound
  self.api_error_code = 404
end

class ActiveRecord::AssociationTypeMismatch
  self.api_error_code = 422
end

class ActiveRecord::RecordInvalid
  def api_error(response)
    io_handler = ::Core::Io::Registry.instance.lookup_for_object(record)
    response.content_error(422, errors_grouped_by_attribute { |attribute| io_handler.json_field_for(attribute) })
  end

  def errors_grouped_by_attribute
    record.errors.as_json.transform_keys { |k| yield(k) }.transform_values { |v| [v].flatten.uniq }
  end
  private :errors_grouped_by_attribute
end

class ActiveModel::ValidationError
  def api_error(response)
    io_handler = ::Core::Io::Registry.instance.lookup_for_object(model)
    response.content_error(422, errors_grouped_by_attribute { |attribute| io_handler.json_field_for(attribute) })
  end

  def errors_grouped_by_attribute
    model.errors.to_hash { |k, v| [yield(k), [v].flatten.uniq] }
  end
  private :errors_grouped_by_attribute
end

class ActiveRecord::RecordNotSaved
  def api_error(response)
    response.content_error(422, message)
  end
end

class IllegalOperation < RuntimeError
  include ::Core::Service::Error::Behaviour

  self.api_error_code = 501
  self.api_error_message = 'requested action is not supported on this resource'
end

class Aliquot::TagClash
  include Core::Service::Error::Behaviour

  def self.api_error_code
    422
  end
end
