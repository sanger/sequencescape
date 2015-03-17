#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddPacbioCherrypickRequestType < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestType.create!(
        :key => 'pacbio_cherrypick',
        :name => 'PacBio Cherrypick',
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
      RequestType.find_by_key('pacbio_cherrypick').destroy
    end
  end
end
