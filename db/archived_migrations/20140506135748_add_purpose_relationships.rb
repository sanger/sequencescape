#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddPurposeRelationships < ActiveRecord::Migration
  def self.up
    Purpose::Relationship.create!(:parent=>Purpose.find_by_name('Reporter Plate'),:child=>Purpose.find_by_name('Tag PCR'),:transfer_request_type=>RequestType.transfer)
  end

  def self.down

  end
end
