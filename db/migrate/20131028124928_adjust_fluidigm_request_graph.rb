class AdjustFluidigmRequestGraph < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      ptst = RequestType.create!({
        :workflow => Submission::Workflow.find_by_name('Microarray genotyping'),
        :asset_type => 'Well',
        :target_asset_type => 'Well',
        :initial_state => 'pending',
        :key => 'pick_to_snp_type',
        :name => 'Pick to SNP Type',
        :order => 3,
        :request_class_name => 'CherrypickForPulldownRequest'
      }).tap do |rt|
        rt.acceptable_plate_purposes << Purpose.find_by_name!('STA2')
      end

      RequestType.find_by_key('pick_to_fluidigm').update_attributes!(:order=>4)

      CherrypickPipeline.find_by_name('Cherrypick for Fluidigm').request_types << ptst

      tosta = RequestType.find_by_key('pick_to_sta').id
      tosta2 = RequestType.find_by_key('pick_to_sta2').id
      tofluidigm = RequestType.find_by_key('pick_to_fluidigm').id

      SubmissionTemplate.find_by_name('Cherrypick for Fluidigm').update_attributes!(
        :submission_parameters => {
          :request_options=>{
            :initial_state=>{
              tosta =>:pending,
              tosta2 =>:pending,
              ptst => :pending,
              tofluidigm =>:pending
              }
            },
          :request_type_ids_list=>[[tosta],[tosta2],[ptst.id],[tofluidigm]],
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
    ActiveRecord::Base.transaction do
       RequestType.find_by_key('pick_to_fluidigm').update_attributes!(:order=>3)
       RequestType.find_by_key('pick_to_snp_type').destroy
       SubmissionTemplate.find_by_name('Cherrypick for Fluidigm').update_attributes!(
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
end
