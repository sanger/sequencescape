# frozen_string_literal: true

module Api::V2::Sapio::Errors
  class FeatureDisabled < JSONAPI::Exceptions::Error
    def errors
      [
        JSONAPI::Error.new(
          status: :not_found,
          title: 'Not Found',
          code: 'FEATURE_DISABLED',
          detail: 'This endpoint is not currently available.'
        )
      ]
    end
  end

  class Forbidden < JSONAPI::Exceptions::Error
    def errors
      [
        JSONAPI::Error.new(
          status: :forbidden,
          title: 'Forbidden',
          code: 'FORBIDDEN',
          detail: 'Integration Hub API key required.'
        )
      ]
    end
  end

  # Based on https://jsonapi.org/format/#crud-creating-responses-409
  class FieldValueConflict < JSONAPI::Exceptions::Error
    attr_accessor :field, :value

    def initialize(field, value, error_object_overrides = {})
      @field = field
      @value = value
      super(error_object_overrides)
    end

    def errors
      detail_message = "The value #{value} for the field #{field} conflicts with an existing record."
      [
        JSONAPI::Error.new(
          status: :conflict,
          title: 'Conflict',
          code: 'FIELD_VALUE_CONFLICT',
          detail: detail_message,
          source: { pointer: "/data/attributes/#{field}" }
        )
      ]
    end
  end

  class MissingUuid < JSONAPI::Exceptions::Error
    def errors
      [
        JSONAPI::Error.new(
          status: :bad_request,
          title: 'Missing Uuid',
          code: 'MISSING_UUID',
          detail: 'A uuid is required to upsert a Study via this endpoint.',
          source: { pointer: '/data/attributes/uuid' }
        )
      ]
    end
  end

  class MissingSearchParam < JSONAPI::Exceptions::Error
    def errors
      [
        JSONAPI::Error.new(
          status: :bad_request,
          title: 'Missing Search Parameter',
          code: 'MISSING_SEARCH_PARAM',
          detail: 'The required search parameter is missing or blank.',
          source: { parameter: 'filter[name]' }
        )
      ]
    end
  end

  class ResultSetTooLarge < JSONAPI::Exceptions::Error
    def errors
      detail_message =
        'Your search matched too many results. ' \
        'Please refine your query to return fewer results.'
      [
        JSONAPI::Error.new(
          status: :unprocessable_content,
          title: 'Result Set Too Large',
          code: 'RESULT_SET_TOO_LARGE',
          detail: detail_message
        )
      ]
    end
  end

  # A problem with the top level of a request body, at a JSON pointer.
  class InvalidStructure < JSONAPI::Exceptions::Error
    attr_reader :pointer, :detail_message

    def initialize(pointer, detail_message, error_object_overrides = {})
      @pointer = pointer
      @detail_message = detail_message
      super(error_object_overrides)
    end

    # @return [Array<JSONAPI::Error>] one 422 error pointing to the problem
    def errors
      [
        JSONAPI::Error.new(
          status: :unprocessable_content,
          title: 'Invalid Request Structure',
          code: 'INVALID_STRUCTURE',
          detail: detail_message,
          source: { pointer: }
        )
      ]
    end
  end

  # A request ID that was already used with a different payload.
  class PayloadConflict < JSONAPI::Exceptions::Error
    attr_reader :external_id

    def initialize(external_id, error_object_overrides = {})
      @external_id = external_id
      super(error_object_overrides)
    end

    # @return [Array<JSONAPI::Error>] one 409 error pointing to the request ID
    def errors
      [
        JSONAPI::Error.new(
          status: :conflict,
          title: 'Conflict',
          code: 'PAYLOAD_CONFLICT',
          detail: "The request ID #{external_id} was already used with a " \
                  'different payload.',
          source: { pointer: '/request/external_id' }
        )
      ]
    end
  end

  # A payload that doesn't match the schema, the contract with the caller:
  # one error for each problem, each naming the schema and version used.
  class SchemaValidationFailed < JSONAPI::Exceptions::Error
    attr_reader :problems, :schema_meta

    # @param problems [Array<Hash>] the problems, each with :pointer and
    #   :detail
    # @param schema_meta [Hash] the schema's subject and version
    def initialize(problems, schema_meta, error_object_overrides = {})
      @problems = problems
      @schema_meta = schema_meta
      super(error_object_overrides)
    end

    # @return [Array<JSONAPI::Error>] a 422 error for each problem
    def errors
      problems.map do |problem|
        JSONAPI::Error.new(
          status: :unprocessable_content,
          title: 'Payload Does Not Match Schema',
          code: 'SCHEMA_VALIDATION_FAILED',
          detail: problem[:detail],
          source: { pointer: problem[:pointer] },
          meta: schema_meta
        )
      end
    end
  end

  # The schema couldn't be loaded, for example because a setting or a schema
  # file is missing. The caller gets this error; the cause, a configuration
  # problem, is reported to the team only.
  class SchemaUnavailable < JSONAPI::Exceptions::Error
    # @return [Array<JSONAPI::Error>] one 500 error, without the cause
    def errors
      [
        JSONAPI::Error.new(
          status: :internal_server_error,
          title: 'Schema Unavailable',
          code: 'SCHEMA_UNAVAILABLE',
          detail: 'The payload schema could not be loaded.'
        )
      ]
    end
  end

  # A request body that is not valid JSON
  class InvalidJson < JSONAPI::Exceptions::Error
    # @return [Array<JSONAPI::Error>] one 400 error
    def errors
      [
        JSONAPI::Error.new(
          status: :bad_request,
          title: 'Invalid JSON',
          code: 'INVALID_JSON',
          detail: 'The request body is not valid JSON.'
        )
      ]
    end
  end
end
