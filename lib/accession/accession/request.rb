module Accession
  ##
  # Does what is says on the tin.
  # Accepts an Accession::Submission and creates a resource based on the service submission.
  # The resource will be a RestClient::Resource which will relate to the specified
  # accessioning service.
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

    # Post the submission to the appropriate accessioning service
    # It will open the payload of the submission.
    # If the service errors it will return a NullResponse
    # Makes sure that the payload is closed.
    def post
      if valid?
        begin
          Accession::Response.new(resource.post(submission.payload.open))
        rescue StandardError => exception
          Accession::NullResponse.new
        ensure
          submission.payload.close!
        end
      end
    end

  private

    # This is horribe but necessary.
    # Set the proxy to ensure you don't get a bad request error.
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
