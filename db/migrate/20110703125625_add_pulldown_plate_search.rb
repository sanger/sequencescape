#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class AddPulldownPlateSearch < ActiveRecord::Migration
  def self.up
    Search::FindPulldownPlates.create!(:name => 'Find pulldown plates')
  end

  def self.down
    Search::FindPulldownPlates.find_by_name('Find pulldown plates').destroy
  end
end
