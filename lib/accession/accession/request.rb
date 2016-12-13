module Accession
  class Request

    include ActiveModel::Validations

    attr_reader :submission, :resource

    validates_presence_of :submission

    class_attribute :rest_client
    self.rest_client = RestClient::Resource

    def initialize(submission)
      @submission = submission

      @resource = if valid?
        rest_client.new(submission.service.url)
      end
    end

  end
end