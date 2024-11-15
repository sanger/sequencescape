# frozen_string_literal: true

module Api
  module V2
    class SubmissionPoolResource < BaseResource
      attribute :plates_in_submission, readonly: true
      attribute :used_tag2_layout_templates, readonly: true
      attribute :used_tag_layout_templates, readonly: true
    end
  end
end
