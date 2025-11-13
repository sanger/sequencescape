# frozen_string_literal: true

require 'faraday'

module HTTPClients
  # A generic client that communicates to external services over HTTP.
  #
  # Subclass this class to create clients for specific services with custom behaviours.
  class BaseClient
    # Make Faraday connection injectable for easier testing.
    def initialize(conn = nil)
      @conn = conn
    end

    private

    def default_headers
      # convert HTTPClients::TestHTTPClient to Test HTTP Client
      client_name = self.class.name.demodulize.underscore.humanize.titleize
      {
        'User-Agent' => "Sequencescape #{client_name}" # Required by some APIs
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
