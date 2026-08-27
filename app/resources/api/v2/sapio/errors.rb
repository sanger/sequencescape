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
end
