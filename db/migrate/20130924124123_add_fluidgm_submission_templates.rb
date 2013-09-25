class AddFluidgmSubmissionTemplates < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do

      tosta = RequestType.find_by_key('pick_to_sta').id
      tosta2 = RequestType.find_by_key('pick_to_sta2').id
      tofluidgm = RequestType.find_by_key('pick_to_fluidgm').id

      SubmissionTemplate.create!(
        :name => 'Cherrypick for Fluidgm',
        :submission_class_name => 'LinearSubmission',
        :submission_parameters => {
          :request_options=>{
            :initial_state=>{
              tosta =>:pending,
              tosta2 =>:pending,
              tofluidgm =>:pending
              }
            },
          :request_type_ids_list=>[[tosta],[tosta2],[tofluidgm]],
          :workflow_id => Submission::Workflow.find_by_name('Microarray genotyping').id,
          :info_differential => Submission::Workflow.find_by_name('Microarray genotyping').id,
          :input_field_infos => [
            FieldInfo.new(
              :kind => "Selection",:default_value => "Fluidgm 96-96",:parameters => { :selection => ['Fluidgm 96-96','Fluidgm 192-24'] },
              :display_name => "Fluidgm Chip",
              :key => "target_purpose"
          )]
        }
      )

    end
  end

  def self.down
    SubmissionTemplate.find_all_by_name(['Cherrypick for Fluidgm 96:96','Cherrypick for Fluidgm 192:24']).map(&:destroy)
  end
end



