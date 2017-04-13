module Accession
  # Sucks the neccessary attributes from a RestClient response
  class Response
    include ActiveModel::Validations

    attr_reader :code, :body, :xml

    validates_presence_of :code, :body

    # extracts the response code and body from response and pars the body into xml
    def initialize(response)
      @code = response.code
      @body = response.body.to_s

      if success?
        @xml = Nokogiri::XML::Document.parse(body)
      end
    end

    def success?
      code.between?(200, 300)
    end

    def failure?
      code.between?(400, 600)
    end

    # If the request was a success extract a boolean value to state whether accessioning happened
    # based on the xml receipt
    def accessioned?
      return false unless success?
      ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES.include?(
        xml.at('RECEIPT').attribute('success').value
)
    end

    # If the request was successful and the receipt says so extract the accession number
    def accession_number
      return unless success?
      xml.at('SAMPLE').try(:attribute, 'accession').try(:value)
    end

    # If the request failed extract the errors from the receipt.
    def errors
      return unless success?
      xml.search('ERROR').collect(&:text)
    end
  end
end
