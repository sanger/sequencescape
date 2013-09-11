class AddIlluminaCCherrypicking < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestType.create!(
        :key  => 'cherrypick_for_illumina_c',
        :name => 'Cherrypick for Illumina-C',
        :workflow => Submission::Workflow.find_by_name("Next-gen sequencing"),
        :asset_type => 'Well',
        :order => 1,
        :initial_state => 'pending',
        :target_asset_type => 'Well',
        :request_class_name => 'CherrypickForPulldownRequest',
        :product_line => ProductLine.find_by_name('Illumina-C')
        )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_by_key('cherrypick_for_illumina_c').destroy
    end
  end
end
