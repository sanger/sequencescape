# frozen_string_literal: true

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
    def conn
      url = configatron.accession.url
      @conn ||= Faraday.new(url:, headers:, proxy:) do |f|
        f.request :multipart
        f.request :url_encoded
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
      # TODO: confirm that the authorization is correct
      conn_with_auth.request :authorization, :basic, login[:username], login[:password]

      # TODO: confirm that this is the correct endpoint, it should hit accession_service/
      payload = build_payload(files)
      response = conn_with_auth.post('/', payload) # POST to the given API root with the payload as the body
      raise_if_failed(response)
      extract_accession_number(response.body)
    end

    private

    def headers
      default_headers
    end

    # Builds a multipart/form-data payload from a hash of opened File objects.
    #
    # Example:
    #   files = {
    #     'SUBMISSION' => File.open('/path/to/submission.xml'),
    #     'SAMPLE' => File.open('/path/to/sample.xml')
    #   }
    #   payload = build_payload(files)
    #   # => {
    #   #   'SUBMISSION' => Faraday::Multipart::FilePart.new(...),
    #   #   'SAMPLE' => Faraday::Multipart::FilePart.new(...)
    #   # }
    #
    # The multipart filename will be set to the remainder of the file's basename after the first underscore.
    #
    # @param files [Hash{String => File}] Hash mapping file type names to opened File objects.
    # @return [Hash{String => Faraday::Multipart::FilePart}] Hash suitable for use as a multipart/form-data payload.
    def build_payload(files)
      files.transform_values do |file|
        # See https://github.com/lostisland/faraday-multipart?tab=readme-ov-file#usage
        Faraday::Multipart::FilePart.new(
          file,
          'text/plain',
          File.basename(file.path).split('_', 2).last
        )
      end
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

      status_message = response.reason_phrase || 'nil'
      default_message = "Posting of accession submission failed, the response status was #{status_message.upcase}."
      message = extract_error_messages(response.body) || default_message
      raise Accession::ExternalValidationError, message
    end
  end
end
