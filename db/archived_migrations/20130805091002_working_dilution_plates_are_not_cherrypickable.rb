#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class WorkingDilutionPlatesAreNotCherrypickable < ActiveRecord::Migration
  def self.down
    ActiveRecord::Base.transaction do
      Purpose.find_by_name('Working Dilution').update_attributes!(:can_be_considered_a_stock_plate => true)
    end
  end

  def self.up
    ActiveRecord::Base.transaction do
      Purpose.find_by_name('Working Dilution').update_attributes!(:can_be_considered_a_stock_plate => false)
    end
  end
end
