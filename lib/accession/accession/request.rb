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

      if valid?
        @resource = rest_client.new(submission.service.url, submission.service.login)
        set_proxy
      end
    end

    def post
      if valid?
        begin
          Accession::Response.new(resource.post(submission.payload.open))
        rescue StandardError => exception
          puts exception.message
          Accession::NullResponse.new
        ensure
          submission.payload.close!
        end
      end
    end

  private

    def set_proxy
      if configatron.disable_web_proxy == true
        RestClient.proxy = ''
      elsif configatron.proxy.present?
        RestClient.proxy = configatron.proxy
        resource.options[:headers] = { user_agent: "Sequencescape Accession Client (#{Rails.env})" }
      end
    end
  end
end
