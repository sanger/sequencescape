class SubmissionTemplateRequestType < ActiveRecord::Base
  belongs_to :submission_template
  belongs_to :request_type
end
