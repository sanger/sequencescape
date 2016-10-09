# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.
class AddPrelimIdToStudyMetadata < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :study_metadata, :prelim_id, :string
      add_index :study_metadata, :prelim_id
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :study_metadata, :prelim_id
      remove_index :study_metadata, :prelim_id
    end
  end
end
