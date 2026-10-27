# frozen_string_literal: true

# Errors raised while processing an ApiOperation.
module ApiOperation::Errors
  # Raised when the API application has no callback URL, so there is nowhere to deliver to.
  class MissingCallbackUrl < StandardError
  end

  # Raised when the calling system doesn't answer with a success status, so
  # Delayed::Job retries the delivery.
  class DeliveryFailed < StandardError
    # @param url [String] the callback URL
    # @param code [String] the HTTP status code of the response
    def initialize(url, code)
      super("API callback to #{url} failed with HTTP #{code}")
    end
  end
end
