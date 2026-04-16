# frozen_string_literal: true

module HTTPClients
  # Uploads accessioning failure notifications to the Integration Hub for emailing to users.
  #
  # Usage:
  #   ```rb
  #   accessioning_error = Accession::ExternalValidationError.new('Failed to process accessioning response')
  #
  #   client = HTTPClients::AccessioningNotificationClient.new
  #   client.create_notification(accessioning_error)
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

    # Post the submission to the appropriate accessioning service.
    # It will open the payload of the submission and make sure that the payload is closed afterwards.
    #
    # @param login [Hash{Symbol => String}] A hash with :username and :password for basic auth.
    # @param files [Hash{String => File}] A hash mapping of file type names to open File objects.
    #   The filename in the multipart payload will be the part of the file object's name after the first underscore.
    # @return [String] The allocated accession number if successful.
    # @raise [Accession::ExternalValidationError] If the response is not successful or does not indicate success.
    # @raise [Faraday::Error] If the HTTP request fails.
    def submit_and_fetch_accession_number(login, files)
      # Clone the base connection and add basic auth for this request
      conn_with_auth = conn.dup
      conn_with_auth.request :authorization, :basic, login[:user], login[:password]

      payload = build_payload(files)
      response = conn_with_auth.post('', payload) # POST to the given API root with the payload as the body
      extract_accession_number(response.body)
    end

    # Creates a notification in the Integration Hub for a given sample and message.
    # TODO: update this docstring
    # TODO: add tests for this method
    def create_notification(sample, message, etc_etc_etc)
      payload = build_notification_payload(sample, message, etc_etc_etc)
      response = conn.post(NOTIFICATIONS_URL, payload)
      puts "Notification API response: #{response.status} - #{response.body}"
    end

    private

    def headers
      default_headers
    end

    def auth_token
      cache_key = 'integration_hub/auth_token'
      cached_token = Rails.cache.read(cache_key)
      puts 'Using cached auth token {cached_token}' if cached_token.present?
      return cached_token if cached_token.present?

      credentials = configatron.integration_hub
      token_data = get_token_data(credentials)

      puts token_data
      access_token = token_data['access_token']
      expires_in = token_data['expires_in']

      # Refresh 30 seconds early to avoid edge-of-expiry failures
      ttl_seconds = [expires_in.to_i - 30, 60].max

      Rails.cache.write(cache_key,
                        access_token,
                        expires_in: ttl_seconds,
                        race_condition_ttl: 30) # serverless provider can take time to spin up, so allow a bit extra

      puts "Obtained new auth token for accessioning notifications, expires in #{ttl_seconds} seconds"

      access_token
    end

    # Requests a bearer token from a separate authentication service using the OAuth 2.0 Client Credentials Flow.
    #
    #
    # @return [Hash{Symbol => String, Symbol => Integer}] A hash with :access_token and :expires_in keys if successful.
    # @raise [RuntimeError] If the HTTP request fails or returns a non-success status code.
    def get_token_data(integration_hub)
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

    def build_notification_payload(sample, message, _etc_etc_etc) # rubocop:disable Metrics/AbcSize
      {
        channels: [
          {
            type: configatron.accession.notifications.notification_type,
            recipient: configatron.accession.notifications.recipient,
            subject: SUBJECT,
            content_type: configatron.accession.notifications.content_type,
            template_id: configatron.accession.notifications.template_id,
            fields: {
              study_name: sample.studies.first.name, # TODO: update this to be more accurate
              manifest_id: 'manifest-123', # TODO: update this to be the actual manifest ID
              sample_name: sample.name,
              supplier_sample_name: sample.supplier_name,
              accessioning_status_message: message,
              sample_path: Rails.application.routes.url_helpers.sample_url(sample)
            }
          }
        ],
        priority: PRIORITY,
        aggregator_id: 'manifest-123'
      }
    end
  end
end
