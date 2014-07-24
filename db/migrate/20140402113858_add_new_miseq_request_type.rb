class AddNewMiseqRequestType < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
        RequestType.create!(
          :key                =>"qc_miseq_sequencing",
          :name               =>"MiSeq sequencing QC",
          :workflow           => Submission::Workflow.find_by_key('short_read_sequencing'),
          :asset_type         => 'LibraryTube',
          :order              => 1,
          :initial_state      => 'pending',
          :multiples_allowed  => false,
          :request_class_name => "MiSeqSequencingRequest",
          :morphology         => 0,
          :for_multiplexing   => false,
          :billable           => true,
          :deprecated         => false,
          :no_target_asset    => false
          ) do |rt|
          Pipeline.find_by_name('MiSeq sequencing').request_types << rt
        end
      end
  end

  def self.down
    RequestType.find_by_name("MiSeq sequencing QC").destroy
  end
end
