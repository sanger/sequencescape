
class AddNewRequestTypesForPlateBasedIlluminaBMxLibraryCreation < ActiveRecord::Migration

  # require 'control_request_type_creation'
  #
  # class Pipeline < ActiveRecord::Base
  #   include ControlRequestTypeCreation
  # end

  def plate_purpose
    PlatePurpose.find_by_name('ILB_STD_INPUT')
  end

  def request_types
    [
      {
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
      }
    ]
  end

  def self.up
    ActiveRecord::Base.transaction do

      request_types.each do |config|
        RequestType.create!(config).tap do |request_type|
          request_type.acceptable_plate_purposes  << plate_purpose
        end
      end

    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      request_types.each do |config|
        RequestType.find_by_key(config[:key]).destroy
      end
    end
  end

end
