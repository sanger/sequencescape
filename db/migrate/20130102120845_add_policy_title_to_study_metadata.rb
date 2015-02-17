#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddPolicyTitleToStudyMetadata < ActiveRecord::Migration
  def self.up
    # No constraints, as not all studies need a policy title
    # Also, even those that do, the already accessioned ones will
    # be missing titles.
    add_column :study_metadata, :dac_policy_title, :string
  end

  def self.down
    remove_column :study_metadata, :dac_policy_title
  end
end
