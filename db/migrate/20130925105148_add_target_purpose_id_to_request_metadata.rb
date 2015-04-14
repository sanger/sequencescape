#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddTargetPurposeIdToRequestMetadata < ActiveRecord::Migration
  def self.up
    add_column :request_metadata, :target_purpose_id, :integer
  end

  def self.down
    remove_column :request_metadata, :target_purpose_id
  end
end
