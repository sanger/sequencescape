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
  class AccessioningNotificationClient < BaseClient
    def conn
      url = configatron.accession_notifications.url
      @conn ||= Faraday.new(url:, headers:, proxy:) do |f|
        f.response :json
      end
    end

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
      raise_if_failed(response)
      extract_accession_number(response.body)
    end

    # Creates a notification in the Integration Hub for a given sample and message.
    # TODO: update this docstring
    def create_notification(sample, message, etc_etc_etc)
      conn.request :authorization, 'Bearer', -> { auth_token }

      payload = build_notification_payload(sample, message, etc_etc_etc)
      response = conn.post('/notifications/v1', payload.to_json)
      raise_if_failed(response)
    end

    private

    def auth_token
      cache_key = 'accession_notifications/auth_token'
      cached_token = Rails.cache.read(cache_key)
      return cached_token if cached_token.present?

      credentials = configatron.accession_notifications.credentials
      token_data = get_bearer_token(credentials)

      # Refresh 30 seconds early to avoid edge-of-expiry failures
      ttl_seconds = [token_data[:expires_in].to_i - 30, 1].max

      Rails.cache.write(cache_key,
                        token_data[:access_token],
                        expires_in: ttl_seconds,
                        race_condition_ttl: 30) # serverless provider can take time to spin up, so allow a bit extra

      token_data[:access_token]
    end

    # Requests a bearer token from a separate authentication service using the OAuth 2.0 Client Credentials Flow.
    #
    # @param credentials [Hash{Symbol => String}] A hash with :client_id, :client_secret, and :auth_token_url.
    # @return [Hash{Symbol => String, Symbol => Integer}] A hash with :access_token and :expires_in keys if successful.
    # @raise [RuntimeError] If the HTTP request fails or returns a non-success status code.
    def get_token_data(credentials)
      response = Faraday.post(credentials.auth_token_url) do |req|
        req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        req.body = URI.encode_www_form(
          grant_type: 'client_credentials',
          client_id: credentials.client_id,
          client_secret: credentials.client_secret
        )
      end

      raise "Failed to obtain auth token: #{response.status} - #{response.body}" unless response.success?

      JSON.parse(response.body)
    end
  end
end
