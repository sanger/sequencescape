#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddLotNumberSearch < ActiveRecord::Migration

  class Search::FindLotByLotNumber < Search; end

  def self.up
    Search::FindLotByLotNumber.create!(:name=>'Find lot by lot number')
  end

  def self.down
    Search.find_by_name('Find lot by lot number').destroy!
  end
end
