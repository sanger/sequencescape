class AddIlluminaCCherrypickSubmissionTemplate < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      request_type_id = RequestType.find_by_key!('illumina_c_cherrypick').id
      SubmissionTemplate.create!(
        :name => 'Illumina-C - Cherrypick Internally',
        :submission_class_name => 'LinearSubmission',
        :submission_parameters => {
          :info_differential=>Submission::Workflow.find_by_key("short_read_sequencing").id,
          :request_options=>{
            :initial_state=>{
              request_type_id=>:pending
              }
            },
            :asset_input_methods=>["select an asset group", "enter a list of sample names found on plates"],
            :workflow_id=>Submission::Workflow.find_by_key("short_read_sequencing").id,
            :request_type_ids_list=>[[request_type_id]]}
        )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SubmissionTemplate.find_by_name('Illumina-C - Cherrypick Internally').destroy
    end
  end
end
