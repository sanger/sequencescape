#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddNoPoolingRequestType < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestType.create!(
        :name               => 'Illumina-C Library Creation PCR No Pooling',
        :key                => 'illumina_c_pcr_no_pool',
        :workflow           => Submission::Workflow.find_by_key('short_read_sequencing'),
        :asset_type         => 'Well',
        :order              => 1,
        :initial_state      => 'pending',
        :multiples_allowed  => false,
        :request_class_name => 'IlluminaC::Requests::PcrLibraryRequest',
        :morphology         => 0,
        :for_multiplexing   => false,
        :billable           => true,
        :product_line       => ProductLine.find_by_name('Illumina-C')
      )
      RequestType.create!(
        :name               => 'Illumina-C Multiplexing',
        :key                => 'illumina_c_multiplexing',
        :workflow           => Submission::Workflow.find_by_key('short_read_sequencing'),
        :asset_type         => 'Well',
        :order              => 1,
        :initial_state      => 'pending',
        :multiples_allowed  => false,
        :request_class_name => 'Request::Multiplexing',
        :morphology         => 0,
        :for_multiplexing   => true,
        :billable           => false,
        :product_line       => ProductLine.find_by_name('Illumina-C'),
        :target_purpose     => Purpose.find_by_name('ILC Lib Pool Norm')
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_by_key('illumina_c_pcr_no_pool').destroy
      RequestType.find_by_key('illumina_c_multiplexing').destroy
    end
  end
end
