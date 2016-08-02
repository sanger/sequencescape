#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class RenamePacbioSamplePrepFreezer < ActiveRecord::Migration
  def self.up
    Location.find_by_name('PacBio sample prep freezer').update_attributes!(:name=>'PacBio library prep freezer')
  end

  def self.down
    Location.find_by_name('PacBio library prep freezer').update_attributes!(:name=>'PacBio sample prep freezer')
  end
end
