# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class AddFlexibleCherrypickSubmissionTemplate < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      flex_id = RequestType.find_by(key: 'flexible_cherrypick').id
      cp_ifi = SubmissionTemplate.find_by(name: 'Cherrypick').submission_parameters[:input_field_infos]
      SubmissionTemplate.create!(
        name: 'Flexible Cherrypick',
        submission_class_name: 'LinearSubmission',
        submission_parameters: {
          workflow_id: Submission::Workflow.find_by(key: 'microarray_genotyping').id,
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
