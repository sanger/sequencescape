module Accession
  class Response
    include ActiveModel::Validations

    attr_reader :code, :body, :xml

    validates_presence_of :code, :body

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

    def accessioned?
      return false unless success?
      ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES.include?(
        xml.at("RECEIPT").attribute("success").value)
    end

    def accession_number
      return unless success?
      xml.at("SAMPLE").try(:attribute, "accession").try(:value)
    end

    def errors
      return unless success?
      xml.search("ERROR").collect(&:text)
    end
  end
end
