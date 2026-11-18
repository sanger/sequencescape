# frozen_string_literal: true

module HTTPClients
  # Sends the outcome of an API operation (ApiOperation::CallbackPayload) to calling system.
  #
  # The operation's external_id is also sent as the Idempotency-Key header, so Integration Hub can
  # recognise a callback it has already received.

  # Configuration options (see config/config.rb):
  #
  # configatron
  #   .integration_hub
  #     .operation_callback_url
  #     .operation_callback_open_timeout
  #     .operation_callback_timeout
  class ApiOperationCallbackClient < BaseClient
    IDEMPOTENCY_KEY_HEADER = 'Idempotency-Key'

    # Raised when there is no callback URL to send to
    class NotConfigured < StandardError
    end

    # @param payload [Hash] the outcome, with the operation's :external_id
    # @return [Faraday::Response] the acknowledgement
    # @raise [NotConfigured] if no callback URL is configured
    # @raise [Faraday::Error] if the request fails, times out, or is not answered with a 2xx status
    def deliver(payload)
      raise NotConfigured, 'integration_hub.operation_callback_url is not configured' if callback_url.blank?

      conn.post do |request|
        request.headers[IDEMPOTENCY_KEY_HEADER] = payload.fetch(:external_id)
        request.body = payload
      end
    end

    private

    def conn
      @conn ||=
        Faraday.new(url: callback_url, headers: default_headers, proxy: proxy) do |f|
          f.request :json
          f.response :raise_error
          f.options.open_timeout = settings.operation_callback_open_timeout
          f.options.timeout = settings.operation_callback_timeout
        end
    end

    def callback_url
      settings.fetch(:operation_callback_url, nil)
    end

    def settings
      configatron.integration_hub
    end
  end
end
