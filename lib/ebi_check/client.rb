# frozen_string_literal: true

# This module provides a client for accessing EBI EGA and ENA accession
# services in order to retrieve submitted study and sample XML data.
# It uses the same endpoint URL for both EGA and ENA, differing only in
# the basic authentication credentials provided.
#
# The client is initialised using the class methods to set the base URL for
# the desired data type (samples or studies) and the appropriate credentials
# for EGA or ENA. The EGA accession numbers typically start with "EGA".
#
# The available class methods are:
# - .for_ega_samples - to access EGA sample data
# - .for_ega_studies - to access EGA study data
# - .for_ena_samples - to access ENA sample data
# - .for_ena_studies - to access ENA study data
#
# Example usage:
#
#   ega_study_client = EbiCheck::Client.for_ega_studies
#   response = ega_study_client.get('EGAS12345678901')
#
#   ena_sample_client = EbiCheck::Client.for_ena_samples
#   response = ena_sample_client.get('ERS12345678')
#
# The response from the .get method is a Faraday::Response object,
# with the XML data accessible via the .body method.
#
module EbiCheck
  class Client < HTTPClients::BaseClient
    # Initializes a new EbiCheck::Client instance.
    # @param url [String] The base URL for the service
    # @param options [Hash] Options including user credentials
    # @option options [String] :user The username for basic authentication.
    # @option options [String] :password The password for basic authentication.
    def initialize(url, options)
      super()
      @url = File.join(url, '/') # Add trailing slash
      @options = options
    end

    delegate :get, to: :conn

    # Returns a string representation of the client instance with sensitive
    # information (such as the password) redacted.
    # @return [String] The inspected client object with filtered credentials.
    def inspect
      redacted_options = options.dup
      redacted_options[:password] = '[FILTERED]' if redacted_options.key?(:password)
      "#<#{self.class}:0x#{object_id.to_s(16)} @options=#{redacted_options.inspect} @url=#{@url.inspect}>"
    end

    private

    attr_reader :url, :options

    # Builds a Faraday connection for the client. This connection is configured
    # with the base URL, headers, proxy settings, and basic authentication
    # using the provided user credentials. This connection is memoized to avoid
    # recreating it on each request.
    # @return [Faraday::Connection] The configured Faraday connection.
    def conn
      @conn ||= Faraday.new(url:, headers:, proxy:) do |f|
        f.request :url_encoded
        f.request :authorization, :basic, options[:user], options[:password]
      end
    end

    class << self
      # Creates a client for accessing EGA sample data.
      # @return [EbiCheck::Client] The EGA samples client.
      def for_ega_samples
        new(samples_url, ega_options)
      end

      # Creates a client for accessing EGA study data.
      # @return [EbiCheck::Client] The EGA studies client.
      def for_ega_studies
        new(studies_url, ega_options)
      end

      # Creates a client for accessing ENA study data.
      # @return [EbiCheck::Client] The ENA studies client.
      def for_ena_studies
        new(studies_url, ena_options)
      end

      # Creates a client for accessing ENA sample data.
      # @return [EbiCheck::Client] The ENA samples client.
      def for_ena_samples
        new(samples_url, ena_options)
      end

      private

      # Returns the base URL for accessing samples.
      # @return [String] The samples URL.
      def samples_url
        File.join(drop_box_url, 'samples/') # Add segment with trailing slash
      end

      # Returns the base URL for accessing studies.
      # @return [String] The studies URL.
      def studies_url
        File.join(drop_box_url, 'studies/') # Add segment with trailing slash
      end

      # Returns the drop box URL from the configuration, ensuring it has a
      # trailing slash.
      # @return [String] The drop box URL.
      def drop_box_url
        url = configatron.accession.drop_box_url!
        File.join(url, '/') # Add trailing slash
      end

      # Returns the options for EGA clients for basic authentication.
      # @return [Hash] The EGA options.
      #   - :user [String] The EGA username.
      #   - :password [String] The EGA password.
      def ega_options
        configatron.accession.ega!.to_hash
      end

      # Returns the options for ENA clients for basic authentication.
      # @return [Hash] The ENA options.
      #   - :user [String] The ENA username.
      #   - :password [String] The ENA password.
      def ena_options
        configatron.accession.ena!.to_hash
      end
    end

    # Adds default headers to the client requests such as User-Agent.
    # @return [Hash] The default headers for the client.
    def headers
      default_headers
    end
  end
end
