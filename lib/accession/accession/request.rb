module Accession
  class Request

    include ActiveModel::Validations

    attr_reader :submission, :resource

    validates_presence_of :submission

    class_attribute :rest_client
    self.rest_client = RestClient::Resource

    def self.post(submission)
      new(submission).post
    end

    def initialize(submission)
      @submission = submission

      @resource = if valid?
        rest_client.new(submission.service.url)
      end
    end

    def post
      if valid?
        begin
          Accession::Response.new(resource.post(submission.to_xml))
        rescue StandardError => exception
          Accession::NullResponse.new
        end
      end
    end

  end
end