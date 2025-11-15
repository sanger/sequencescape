# frozen_string_literal: true

require 'exception_notification'

module HTTPClients
  # Submits records to EBI for accessioning using v1 of their accessioning API.
  #
  # Usage:
  #   ```rb
  #   client = HTTPClients::AccessioningClient.new
  #   accession_number = client.submit_and_fetch_accession_number(submission)
  #   ````
  #
  # API documentation: https://ena-docs.readthedocs.io/en/latest/submit/general-guide/webin-v1.html
  class AccessioningV1Client < BaseClient
    def initialize(conn = nil)
      url = configatron.accession.url
      # Make Faraday connection injectable for easier testing.
      super(conn || Faraday.new(url:, headers:, proxy:))
    end

    # Post the submission to the appropriate accessioning service.
    # It will open the payload of the submission and make sure that the payload is closed afterwards.
    #
    # @param submission [Accession::Submission] The submission to be posted to the accessioning service.
    # @return [String] The allocated accession number if successful.
    # @raise [Accession::ExternalValidationError] If the response is not successful or does not indicate success.
    # @raise [Faraday::Error] If the HTTP request fails.
    def submit_and_fetch_accession_number(submission)
      login = submission.service.login
      payload = submission.payload.open

      # Clone the base connection and add basic auth for this request
      conn = @conn.dup
      conn.request :authorization, :basic, login[:username], login[:password]

      response = conn.post(nil, payload) # POST to the given API root with the payload as the body
      raise_if_failed(response)
      extract_accession_number(response.body)
    ensure
      submission&.payload&.close!
    end

    private

    def headers
      default_headers.merge('Content-Type' => 'application/xml')
    end

    def receipt_succeeded?(response_body)
      xml_doc = Nokogiri::XML(response_body)
      success_attr = xml_doc.at('RECEIPT')&.attribute('success')&.value
      ActiveModel::Type::Boolean.new.cast(success_attr)
    end

    def receipt_failed?(response_body)
      !receipt_succeeded?(response_body)
    end

    def extract_accession_number(response_body)
      xml_doc = Nokogiri::XML(response_body)
      xml_doc.at('SAMPLE').try(:attribute, 'accession').try(:value)
    end

    def extract_error_messages(response_body)
      xml_doc = Nokogiri::XML(response_body)
      messages = xml_doc.search('ERROR').collect(&:text).join('; ')
      messages.presence
    end

    def raise_if_failed(response)
      return unless receipt_failed?(response.body)

      message = extract_error_messages(response.body) || 'Posting of accession submission failed'
      raise Accession::ExternalValidationError, message
    end
  end
end
