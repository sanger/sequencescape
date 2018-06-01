
class AddFlexibleCherrypickSubmissionTemplate < ActiveRecord::Migration
  class SubmissionWorkflow < ApplicationRecord
    self.table_name = 'submission_workflows'
  end

  def self.up
    ActiveRecord::Base.transaction do
      flex_id = RequestType.find_by(key: 'flexible_cherrypick').id
      cp_ifi = SubmissionTemplate.find_by(name: 'Cherrypick').submission_parameters[:input_field_infos]
      SubmissionTemplate.create!(
        name: 'Flexible Cherrypick',
        submission_class_name: 'LinearSubmission',
        submission_parameters: {
          workflow_id: SubmissionWorkflow.find_by(key: 'microarray_genotyping').id,
          request_options: {
            initial_state: { flex_id => :pending }
          },
          request_type_ids_list: [[flex_id]],
          input_field_infos: cp_ifi
        }
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find_by(name: 'Flexible Cherrypick').destroy
    end
  end
end
