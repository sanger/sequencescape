#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddDonorIdColumn < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :sample_metadata, :cancer_donor_id,:string
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :sample_metadata, :cancer_donor_id
    end
  end
end
