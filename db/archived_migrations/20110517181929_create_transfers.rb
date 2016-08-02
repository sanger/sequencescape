#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class CreateTransfers < ActiveRecord::Migration
  def self.up
    create_table :transfers do |t|
      t.timestamps
      t.string :sti_type
      t.references :source
      t.references :destination, :polymorphic => true
      t.string :transfers, :limit => 1024
    end
  end

  def self.down
    drop_table :transfers
  end
end
