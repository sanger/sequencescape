#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddPacbioCherrypickSubmissionTemplate < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      request_type_id = RequestType.find_by_key!('pacbio_cherrypick').id
      SubmissionTemplate.create!(
        :name => 'PacBio - Cherrypick Only',
        :submission_class_name => 'LinearSubmission',
        :submission_parameters => {
          :info_differential=>Submission::Workflow.find_by_key("short_read_sequencing").id,
          :request_options=>{
            :initial_state=>{request_type_id=>:pending}
          },
          :asset_input_methods=>["select an asset group", "enter a list of sample names found on plates"],
          :workflow_id=>Submission::Workflow.find_by_key("short_read_sequencing").id,
          :request_type_ids_list=>[[request_type_id]]}
      )
      SubmissionTemplate.find_by_name('PacBio').dup.tap do |template|
        template.name = 'PacBio - Cherrypick And Sequence'
        sp = template.submission_parameters
        sp[:request_type_ids_list].unshift([request_type_id])
        template.submission_parameters = sp
      end.save!
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find_by_name('PacBio - Cherrypick Only').destroy
      SubmissionTemplate.find_by_name('PacBio - Cherrypick And Sequence').destroy
    end
  end
end
