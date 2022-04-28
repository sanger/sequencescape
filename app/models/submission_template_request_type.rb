# frozen_string_literal: true
class SubmissionTemplateRequestType < ApplicationRecord
  belongs_to :submission_template
  belongs_to :request_type
end
