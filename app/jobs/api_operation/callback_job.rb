# frozen_string_literal: true

require 'faraday'

# Reports the processing status of an API operation back to the calling system
# by POSTing JSON to the callback URL of the operation's ApiApplication (see
# #callback_url_variable).
#
# Queued once the operation is completed. A failed
# delivery raises, so Delayed::Job retries it. An application with no callback URL also raises.
class ApiOperation::CallbackJob < HTTPClients::BaseClient
  # The environment variable that holds an application's callback URL is named
  # after it: the name in upper case, each run of other characters replaced by
  # an underscore, then this suffix. For example, INTEGRATION_HUB_CALLBACK_URL.
  CALLBACK_URL_SUFFIX = '_CALLBACK_URL'

  attr_reader :api_operation

  def initialize(api_operation_id)
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
  # @raise [ApiOperation::Errors::MissingCallbackUrl] if the application's
  #   variable isn't set
  def callback_url
    url = ENV.fetch(callback_url_variable, nil)
    return url if url.present?

    raise ApiOperation::Errors::MissingCallbackUrl, "#{callback_url_variable} is not set"
  end

  # @return [String] the name of the environment variable that holds the
  #   callback URL of this operation's API application
  def callback_url_variable
    name = api_operation.api_application.name.upcase.gsub(/[^A-Z0-9]+/, '_').gsub(/\A_|_\z/, '')
    "#{name}#{CALLBACK_URL_SUFFIX}"
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
