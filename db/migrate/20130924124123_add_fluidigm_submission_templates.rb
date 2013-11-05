class AddFluidigmSubmissionTemplates < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do

      tosta = RequestType.find_by_key('pick_to_sta').id
      tosta2 = RequestType.find_by_key('pick_to_sta2').id
      tofluidigm = RequestType.find_by_key('pick_to_fluidigm').id

      SubmissionTemplate.create!(
        :name => 'Cherrypick for Fluidigm',
        :submission_class_name => 'LinearSubmission',
        :submission_parameters => {
          :request_options=>{
            :initial_state=>{
              tosta =>:pending,
              tosta2 =>:pending,
              tofluidigm =>:pending
              }
            },
          :request_type_ids_list=>[[tosta],[tosta2],[tofluidigm]],
          :workflow_id => Submission::Workflow.find_by_name('Microarray genotyping').id,
          :info_differential => Submission::Workflow.find_by_name('Microarray genotyping').id,
          :input_field_infos => [
            FieldInfo.new(
              :kind => "Selection",:default_value => "Fluidigm 96-96",:parameters => { :selection => ['Fluidigm 96-96','Fluidigm 192-24'] },
              :display_name => "Fluidigm Chip",
              :key => "target_purpose_name"
          )]
        }
      )

    end
  end

  def self.down
    SubmissionTemplate.find_all_by_name(['Cherrypick for Fluidigm 96:96','Cherrypick for Fluidigm 192:24']).map(&:destroy)
  end
end



