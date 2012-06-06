
class AddNewRequestTypesForPlateBasedIlluminaBMxLibraryCreation < ActiveRecord::Migration

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
      ).tap do |request_type|
        request_type.acceptable_plate_purposes  << PlatePurpose.find_by_name('ILB_STD_INPUT')
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      request_types.each do |config|
        RequestType.find_by_key('Illumina-B STD').destroy
      end
    end
  end

end
