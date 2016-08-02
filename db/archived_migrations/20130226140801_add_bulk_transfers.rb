#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddBulkTransfers < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      create_table :bulk_transfers do |t|
        t.timestamps
        t.references :user
      end
    end
  end

  def self.down
    drop_table :bulk_transfers
  end
end
