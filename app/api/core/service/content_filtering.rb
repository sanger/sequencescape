# frozen_string_literal: true
# Everything coming in and going out should be JSON.
module Core::Service::ContentFiltering
  class InvalidRequestedContentType < ::Core::Service::Error
    self.api_error_code = 406
    self.api_error_message =
      "the 'Accept' header can only be 'application/json' or a supported filetype eg.'sequencescape/qc_file'"
  end

  class InvalidRequestedContentTypeOnFile < ::Core::Service::Error
    self.api_error_code = 406
    self.api_error_message = "the 'Accept' header can only be 'application/json' when submitting a file"
  end

  class InvalidBodyContentType < ::Core::Service::Error
    self.api_error_code = 415
    self.api_error_message =
      "the 'Content-Type' can only be 'application/json' or a supported filetype eg.'sequencescape/qc_file'"
  end

  module Helpers
    def json
      @json
    end

    def process_request_body # rubocop:todo Metrics/AbcSize
      content = request.body.read
      if content.present? && acceptable_types.exclude?(request.content_type)
        raise Core::Service::ContentFiltering::InvalidBodyContentType
      end

      if request.content_type == 'application/json' || content.blank?
        @json = content.blank? ? {} : MultiJson.load(content)
      end
    ensure
      # It's important to ensure that the body IO object has been rewound to the start for other requests.
      request.body.rewind
    end

    def process_response_body
      headers('Content-Type' => request_accepted.first)
    end

    ACCEPTABLE_TYPES = Rails.env.development? ? %w[application/json */*].freeze : ['application/json'].freeze

    def acceptable_types
      ACCEPTABLE_TYPES + ::Api::EndpointHandler.registered_mimetypes
    end

    def check_acceptable_content_type_requested!
      accepts_json_or_star = request.acceptable_media_types.prioritize(*acceptable_types).present?
      raise Core::Service::ContentFiltering::InvalidRequestedContentType unless accepts_json_or_star
    end

    def request_accepted
      request.acceptable_media_types.prioritize(*acceptable_types).map(&:to_s)
    end
  end

  def self.registered(app)
    app.helpers Helpers

    app.before_all_actions do
      check_acceptable_content_type_requested!
      process_request_body
    end

    app.after_all_actions { process_response_body }
  end
end
