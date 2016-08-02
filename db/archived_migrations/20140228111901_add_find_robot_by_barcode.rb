#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddFindRobotByBarcode < ActiveRecord::Migration
  def self.up
    Search::FindRobotByBarcode.create!(:name=>'Find robot by barcode')
  end

  def self.down
    Search::FindRobotByBarcode.find_by_name('Find robot by barcode').destroy
  end
end
