class AddNewRequestTypesForPlateBasedIlluminaBMxLibraryCreation < ActiveRecord::Migration
  class RequestType < ActiveRecord::Base
    set_table_name('request_types')
  end

  def self.up
    ActiveRecord::Base.transaction do
      RequestType.create!(
        :key => 'illumina_b_std',
        :name => 'Illumina-B STD',
        :workflow_id => Submission::Workflow.find_by_key('short_read_sequencing').id,
        :asset_type => 'Well',
        :order => 1,
        :initial_state => 'pending',
        :target_asset_type => 'MultiplexedLibraryTube',
        :multiples_allowed => 0,
        :request_class_name => 'IlluminaB::Requests::StdLibraryRequest',
        :morphology => 0,
        :for_multiplexing => 1,
        :billable => 1,
        :product_line_id => ProductLine.find_by_name('Illumina-B').id
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_by_key('illumina_b_std').destroy
    end
  end

end
