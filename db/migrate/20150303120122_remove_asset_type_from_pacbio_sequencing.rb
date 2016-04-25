#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class RemoveAssetTypeFromPacbioSequencing < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Pipeline.find_by_name('PacBio Sequencing').update_attributes!(:asset_type=>nil)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Pipeline.find_by_name('PacBio Sequencing').update_attributes!(:asset_type=>'Well')
    end
  end
end
