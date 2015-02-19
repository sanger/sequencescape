#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddPacBioTransfer < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestType.create!(
        :key                => 'initial_pacbio_transfer',
        :name               => 'Initial Pacbio Transfer',
        :asset_type         => 'Well',
        :request_class_name => 'PacBioSamplePrepRequest::Initial',
        :order              => 1,
        :target_purpose     => Purpose.find_by_name('PacBio Sheared')
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_by_key('initial_pacbio_transfer').destroy
    end
  end
end
