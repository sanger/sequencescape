# frozen_string_literal: true

module HTTPClients
  # Uploads accessioning failure notifications to the Integration Hub for emailing to users.
  #
  # Usage:
  #   ```rb
  #   sample = Sample.last
  #   message = "Accessioning failed due to XYZ reason"
  #   failure_groups = ['Internal validation failure', 'ENA validation failure'] # can be any consistent values
  #
  #   client = HTTPClients::AccessioningNotificationClient.new
  #   client.create_notification(sample, message, failure_groups)
  #   ````
  #
  # API documentation: https://integration-hub.sanger.ac.uk/docs/notification-api/how-to-use/#invoking-the-api
  #
  # Configuration options (see config/config.rb):
  #
  # configatron
  #   .integration_hub
  #     .auth_token_url
  #     .base_url
  #     .notifications_api
  #       .client_id
  #       .client_secret
  #   .accession
  #     .notifications
  #       .recipient
  #       .template_id
  #       .notification_type
  #       .content_type

  class AccessioningNotificationClient < BaseClient
    NOTIFICATIONS_URL = '/notifications/v1'
    PRIORITY = 'BATCH'
    SUBJECT = 'Accessioning Failure Notification'

    def conn
      url = configatron.integration_hub.base_url
      @conn ||= Faraday.new(url:, headers:, proxy:) do |f|
        f.request :json
        f.request :authorization, 'Bearer', -> { auth_token }

        f.response :raise_error # Raise exceptions on 4xx/5xx responses
        f.response :json
      end
    end

    # TODO: add tests for auth-token retrieval and caching

    # Creates a notification in the Integration Hub for a given sample and message.
    # TODO: update this docstring
    # TODO: add tests for this method
    # @param sample [Sample] The sample associated with the notification.
    # @param message [String] The message to include in the notification.
    # @param failure_groups [Array<String>] An array of failure group names to include in the notification summary.
    # @return [String] The ID of the created notification if successful.
    # @raise [Faraday::Error] If the HTTP request fails.
    def create_notification(sample, message, failure_groups)
      Rails.logger.info("Creating notification for sample '#{sample.name}'")
      payload = build_notification_payload(sample, message, failure_groups)
      response = conn.post(NOTIFICATIONS_URL, payload)
      response.body['notification_id']
    end

    private

    def headers
      default_headers
    end

    def auth_token
      cache_key = 'integration_hub/auth_token'
      cached_token = Rails.cache.read(cache_key)
      return cached_token if cached_token.present?

      credentials = configatron.integration_hub
      token_data = get_token_data(credentials)

      access_token = token_data['access_token']
      expires_in = token_data['expires_in']

      # Refresh 30 seconds early to avoid edge-of-expiry failures
      ttl_seconds = [expires_in.to_i - 30, 60].max

      Rails.cache.write(cache_key, access_token, expires_in: ttl_seconds, race_condition_ttl: 10)

      access_token
    end

    # Requests a bearer token from a separate authentication service using the OAuth 2.0 Client Credentials Flow.
    #
    #
    # @return [Hash{Symbol => String, Symbol => Integer}] A hash with :access_token and :expires_in keys if successful.
    # @raise [RuntimeError] If the HTTP request fails or returns a non-success status code.
    def get_token_data(integration_hub)
      Rails.logger.info('Requesting new auth token for Integration Hub Notification API')
      auth_conn = Faraday.new(url: integration_hub.auth_token_url) do |f|
        f.request :url_encoded
        f.response :json
      end

      response = auth_conn.post do |req|
        # req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        # TODO: add test for correct content type header
        req.body = {
          grant_type: 'client_credentials',
          client_id: integration_hub.notifications_api.client_id,
          client_secret: integration_hub.notifications_api.client_secret
        }
      end

      raise "Failed to obtain auth token: #{response.status} - #{response.body}" unless response.success?

      response.body
    end

    def build_notification_payload(sample, message, failure_groups)
      # the presence of a to http://localhost causes a 502 response from the Notifications API, default to uat instead
      sample_path = Rails.application.routes.url_helpers.sample_url(sample, host: 'uat.sequencescape.sanger.ac.uk')
      notifications_config = configatron.accession.notifications
      {
        channels: [
          {
            type: notifications_config.notification_type,
            recipient: notifications_config.recipient,
            content_type: notifications_config.content_type,
            template_id: notifications_config.template_id,
            subject: SUBJECT,
            fields: {
              study_name: sample.studies.first.name, # TODO: update this to be more accurate
              manifest_id: 'manifest-123', # TODO: update this to be the actual manifest ID
              sample_name: sample.name,
              supplier_sample_name: sample.supplier_name || 'unknown supplier sample name',
              sample_path: sample_path,
              accessioning_status_message: message,
              failure_groups: failure_groups
            }
          }
        ],
        priority: PRIORITY,
        aggregator_id: 'manifest-123' # TODO: update this to be the actual manifest ID
      }
    end
  end
end
