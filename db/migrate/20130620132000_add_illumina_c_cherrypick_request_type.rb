class AddIlluminaCCherrypickRequestType < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestType.create!(
        :key => 'illumina_c_cherrypick',
        :name => 'Illumina-C Cherrypick',
        :workflow_id => Submission::Workflow.find_by_key("short_read_sequencing").id,
        :asset_type => 'Well',
        :order => 2,
        :initial_state => 'pending',
        :target_asset_type => 'Well',
        :request_class_name => 'Request'
        )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_by_key('illumina_c_cherrypick').destroy
    end
  end
end
