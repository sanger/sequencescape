# frozen_string_literal: true

require 'exception_notification'

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
      return unless valid?

      Accession::Response.new(resource.post(submission.payload.open))
    rescue StandardError => e
      handle_exception(e, message: 'Posting of accession submission failed')
      Accession::NullResponse.new
    ensure
      submission&.payload&.close!
    end

    private

    # This is horribe but necessary.
    # Set the proxy to ensure you don't get a bad request error.
    def set_proxy # rubocop:todo Metrics/AbcSize
      if configatron.disable_web_proxy == true
        RestClient.proxy = nil
      elsif configatron.fetch(:proxy).present?
        RestClient.proxy = configatron.proxy
        resource.options[:headers] = { user_agent: "Sequencescape Accession Client (#{Rails.env})" }
      elsif ENV['http_proxy'].present?
        RestClient.proxy = ENV['http_proxy']
      end
    end

    def handle_exception(error, message)
      Rails.logger.error(error.message)
      ExceptionNotifier.notify_exception(error, { message: message, submission: submission.to_xml })
    end
  end
end
