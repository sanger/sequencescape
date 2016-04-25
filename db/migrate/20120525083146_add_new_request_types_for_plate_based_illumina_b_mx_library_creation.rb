#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class AddNewRequestTypesForPlateBasedIlluminaBMxLibraryCreation < ActiveRecord::Migration
  class RequestType < ActiveRecord::Base
    self.table_name =('request_types')
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
