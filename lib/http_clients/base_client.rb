# frozen_string_literal: true

require 'faraday'

module HTTPClients
  # A generic client that communicates to external services over HTTP.
  #
  # Subclass this class to create clients for specific services with custom behaviours.
  #
  # Usage:
  #   client = HTTPClient.new(base_url: 'http://example.com', headers: { 'Authorization' => 'token' })
  class BaseClient
    # Make Faraday connection injectable for easier testing.
    def initialize(conn = nil)
      @conn = conn
    end

    private

    def default_headers
      # convert HTTPClient to HTTP Client, LabwareClient to Labware Client, ExternalAPIClient to External API Client, etc.
      client_name = self.class.name.demodulize.underscore.humanize.titleize
      {
        'User-Agent' => "Sequencescape #{client_name}"
      }
    end

    def proxy
      return nil if configatron.disable_web_proxy == true
      return configatron.proxy if configatron.fetch(:proxy).present?
      return ENV['http_proxy'] if ENV['http_proxy'].present?

      nil
    end
  end
end
