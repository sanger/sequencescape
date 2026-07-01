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

  class MissingSearchParam < JSONAPI::Exceptions::Error
    def errors
      [
        JSONAPI::Error.new(
          status: :bad_request,
          title: 'Bad Request',
          code: 'MISSING_SEARCH_PARAM',
          detail: 'The required search parameter is missing or blank.'
        )
      ]
    end
  end

  class ResultSetTooLarge < JSONAPI::Exceptions::Error
    def errors
      detail_message =
        'Your query matched too many results. ' \
        'Please refine your query to return fewer results.'
      [
        JSONAPI::Error.new(
          status: :bad_request,
          title: 'Bad Request',
          code: 'RESULT_SET_TOO_LARGE',
          detail: detail_message
        )
      ]
    end
  end
end
