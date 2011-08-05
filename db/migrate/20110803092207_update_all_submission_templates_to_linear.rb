class UpdateAllSubmissionTemplatesToLinear < ActiveRecord::Migration
  def self.up
    SubmissionTemplate.update_all('submission_class_name="LinearSubmission"')
  end

  def self.down
    # Nothing to really do here as it remains consistent
  end
end
