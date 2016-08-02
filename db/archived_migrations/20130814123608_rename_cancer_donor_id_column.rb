#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class RenameCancerDonorIdColumn < ActiveRecord::Migration
  def self.up
    rename_column :sample_metadata, :cancer_donor_id, :donor_id
  end

  def self.down
    rename_column :sample_metadata, :donor_id, :cancer_donor_id
  end
end
