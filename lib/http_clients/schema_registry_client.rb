# frozen_string_literal: true

require 'faraday'

module HTTPClients
  # Reads schemas from a schema registry with the Confluent API, such as
  # Redpanda's.
  #
  # Usage:
  #   ```rb
  #   client = HTTPClients::SchemaRegistryClient.new('http://localhost:8081')
  #   client.schema_version('work-order-schema', 3)
  #   # => { 'subject' => 'work-order-schema', 'version' => 3, 'id' => 1,
  #   #      'schemaType' => 'JSON', 'schema' => '{"$schema": ...}' }
  #   ```
  class SchemaRegistryClient < BaseClient
    # Seconds to wait for a connection, and then for the response. They are
    # short, as a schema is fetched while a request waits for it.
    OPEN_TIMEOUT = 2
    TIMEOUT = 5

    # The media type of the registry's API
    MEDIA_TYPE = 'application/vnd.schemaregistry.v1+json'

    # @param url [String] the registry's base URL, without /subjects
    def initialize(url)
      super()
      @url = url
    end

    # @return [Faraday::Connection] a connection that raises an error for an
    #   error response and parses JSON
    def conn
      @conn ||= Faraday.new(
        url: @url,
        headers: default_headers.merge('Accept' => MEDIA_TYPE),
        proxy: proxy,
        request: { open_timeout: OPEN_TIMEOUT, timeout: TIMEOUT }
      ) do |f|
        f.response :raise_error
        f.response :json
      end
    end

    # Fetches one version of a subject's schema.
    #
    # @param subject [String] the subject's name
    # @param version [Integer, :latest] the version, or :latest
    # @return [Hash] the registry's answer: subject, version, id, schema and,
    #   for types other than Avro, schemaType
    # @raise [Faraday::ResourceNotFound] if the registry doesn't hold it
    # @raise [Faraday::Error] if the registry can't be reached, takes too
    #   long or answers with another error
    def schema_version(subject, version)
      conn.get(
        "subjects/#{ERB::Util.url_encode(subject)}/versions/" \
        "#{ERB::Util.url_encode(version.to_s)}"
      ).body
    end
  end
end
