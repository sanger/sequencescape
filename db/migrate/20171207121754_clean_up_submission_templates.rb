# frozen_string_literal: true

# We've removed submission workflow
# Submission templates sometimes include a reference to this in
# their submission parameters
class CleanUpSubmissionTemplates < ActiveRecord::Migration[5.1]
  def change
    transaction do
      SubmissionTemplate.all.each do |template|
        template.submission_parameters.delete(:workflow_id)
        template.save!
      end
    end
  end
end
