# Everything coming in and going out should be JSON.
module Core::Service::ContentFiltering
  class InvalidRequestedContentType < ::Core::Service::Error
    self.api_error_code    = 406
    self.api_error_message = "the 'Accept' header can only be 'application/json' or a supported filetype eg.'sequencescape/qc_file'"
  end

  class InvalidBodyContentType < ::Core::Service::Error
    self.api_error_code    = 415
    self.api_error_message = "the 'Content-Type' can only be 'application/json'"
  end

  module Helpers
    def json
      @json
    end

    def process_json_request_body
      content = request.body.read
      raise Core::Service::ContentFiltering::InvalidBodyContentType if not content.blank? and request.content_type != 'application/json'
      @json   = content.blank? ? {} : JSON.parse(content)
    ensure
      # It's important to ensure that the body IO object has been rewound to the start for other requests.
      request.body.rewind
    end

    def process_response_body
      headers('Content-Type' => request_accepted)
    end

    def process_json_response_body
     headers('Content-Type' => 'application/json')
    end

    ACCEPTABLE_TYPES = [ 'application/json' ]
    ACCEPTABLE_TYPES << '*/*' if Rails.env == 'development'

    def acceptable_types
      ACCEPTABLE_TYPES.concat(::Api::EndpointHandler.registered_mimetypes)
    end

    def check_acceptable_content_type_requested!
      accepts_json_or_star = !request.acceptable_media_types.prioritize(*acceptable_types).blank?
      raise Core::Service::ContentFiltering::InvalidRequestedContentType unless accepts_json_or_star
    end

    def request_accepted
      request.acceptable_media_types.prioritize(*acceptable_types).to_s
    end

  end

  def self.registered(app)
    app.helpers Helpers

    app.before_all_actions do
      check_acceptable_content_type_requested!
      process_json_request_body
    end

    app.after_all_actions do
      process_response_body
    end
  end
end
