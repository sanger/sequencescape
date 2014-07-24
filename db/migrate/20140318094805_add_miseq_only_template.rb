class AddMiseqOnlyTemplate < ActiveRecord::Migration
  def self.up
    SubmissionTemplate.create!(
      :name => 'MiSeq for TagQC',
      :submission_class_name => 'LinearSubmission',
      :submission_parameters => {
        :request_options=>{
        },
        :request_type_ids_list=>[[miseq]],
        :workflow_id=>Submission::Workflow.find_by_key('short_read_sequencing').id,
        :info_differential=>Submission::Workflow.find_by_key('short_read_sequencing').id
      },
      :superceded_by_id => -2
    )
  end

  def self.miseq
    RequestType.find_by_key('miseq_sequencing').id
  end

  def self.down
    SubmissionTemplate.find_by_name('MiSeq for TagQC').destroy
  end
end
