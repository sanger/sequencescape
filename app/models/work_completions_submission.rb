# frozen_string_literal: true
# Simple join for has_and_belongs_to_many
class WorkCompletionsSubmission < ApplicationRecord
  belongs_to :work_completion, inverse_of: :work_completions_submissions
  belongs_to :submission, validate: false
end
