#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class AddMultiplexedPacbioRequestTypes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestType.create!(
        :name               => "PacBio Tagged Library Prep",
        :key                => "pacbio_tagged_library_prep",
        :asset_type         => "Well",
        :billable           => false,
        :deprecated         => false,
        :for_multiplexing   => false,
        :initial_state      => "pending",
        :morphology         => 0,
        :multiples_allowed  => false,
        :no_target_asset    => false,
        :order              => 1,
        :request_class_name => "PacBioSamplePrepRequest",
        :workflow_id        => Submission::Workflow.find_by_key('short_read_sequencing')
      )
      RequestType.create!(
        :name => "PacBio Multiplexed Sequencing",
        :asset_type => "PacBioLibraryTube",
        :key => "pacbio_multiplexed_sequencing",
        :billable => false,
        :deprecated => false,
        :for_multiplexing => true,
        :initial_state => "pending",
        :morphology => RequestType::CONVERGENT,
        :multiples_allowed => true,
        :no_target_asset => false,
        :order => 1,
        :request_class_name => "PacBioSequencingRequest",
        :workflow_id => Submission::Workflow.find_by_key('short_read_sequencing')
      ) do | request_type|
        request_type.request_type_validators.build([
          {:request_option=>'insert_size',
          :valid_options=>RequestType::Validator::ArrayWithDefault.new([500,1000,2000,5000,10000,20000],500),
          :request_type=>request_type},
          {:request_option=>'sequencing_type',
          :valid_options=>RequestType::Validator::ArrayWithDefault.new(['Standard','MagBead','MagBead OneCellPerWell v1'],'Standard'),
          :request_type=>request_type}
        ])
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_by_key!("pacbio_tagged_sample_prep").destroy
      RequestType.find_by_key!("pacbio_multiplexed_sequencing").destroy
    end
  end
end
