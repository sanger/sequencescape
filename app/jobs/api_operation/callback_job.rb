# frozen_string_literal: true

require 'faraday'

# Reports the processing status of an API operation back to the calling system
# by POSTing JSON to the callback URL configured for the operation's
# ApiApplication in configatron.api_operations_callback_urls, keyed by application name.
#
# Queued once the operation is completed. A failed
# delivery raises, so Delayed::Job retries it. An application with no callback URL also raises.
class ApiOperation::CallbackJob < HTTPClients::BaseClient
  attr_reader :api_operation

  def initialize(api_operation_id)
    super()
    @api_operation = ApiOperation.find(api_operation_id)
  end

  def perform
    url = callback_url
    response = post(URI(url), body(api_operation))
    api_operation.update!(response_delivered_at: Time.current)

    return if response.success?

    raise ApiOperation::Errors::DeliveryFailed.new(url, response.status)
  end

  private

  # @return [String] where to report the status to the calling system
  # @raise [ApiOperation::Errors::MissingCallbackUrl] if no URL is configured for the application
  def callback_url
    application_name = api_operation.api_application.name
    url = configatron.fetch(:api_operations_callback_urls, {})[application_name]
    return url if url.present?

    raise ApiOperation::Errors::MissingCallbackUrl, "No callback URL configured for #{application_name}"
  end

  def body(api_operation)
    payload = {
      operation_type: api_operation.operation_type,
      external_id: api_operation.external_id,
      status: api_operation.status
    }
    payload[:error_details] = api_operation.error_details if api_operation.error_details.present?
    payload
  end

  def post(uri, body)
    Faraday.new(
      headers: default_headers.merge('Content-Type' => 'application/json'),
      proxy: proxy
    ).post(uri.to_s, body.to_json)
  end
end
