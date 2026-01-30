# frozen_string_literal: true

module EbiCheck
  class Client < HTTPClients::BaseClient
    def initialize(url, options)
      super()
      @url = self.class.ensure_trailing_slash(url)
      @options = options
    end

    delegate :get, to: :conn

    def inspect
      redacted_options = options.dup
      redacted_options[:password] = '[FILTERED]' if redacted_options.key?(:password)
      "#<#{self.class}:0x#{object_id.to_s(16)} @options=#{redacted_options.inspect} @url=#{@url.inspect}>"
    end

    private

    attr_reader :url, :options

    def conn
      @conn ||= Faraday.new(url:, headers:, proxy:) do |f|
        f.request :url_encoded
        f.request :authorization, :basic, options[:user], options[:password]
      end
    end

    class << self
      def for_ega_samples
        new(samples_url, ega_options)
      end

      def for_ega_studies
        new(studies_url, ega_options)
      end

      def for_ena_studies
        new(studies_url, ena_options)
      end

      def for_ena_samples
        new(samples_url, ena_options)
      end

      def ensure_trailing_slash(url)
        url.end_with?('/') ? url : "#{url}/"
      end

      private

      def samples_url
        URI.join(drop_box_url, 'samples/').to_s
      end

      def studies_url
        URI.join(drop_box_url, 'studies/').to_s
      end

      def drop_box_url
        url = configatron.accession.drop_box_url!
        ensure_trailing_slash(url)
      end

      def ega_options
        configatron.accession.ega!.to_hash
      end

      def ena_options
        configatron.accession.ena!.to_hash
      end
    end

    def headers
      default_headers
    end
  end
end
