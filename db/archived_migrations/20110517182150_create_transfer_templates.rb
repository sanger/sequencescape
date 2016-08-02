#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class CreateTransferTemplates < ActiveRecord::Migration
  def self.up
    create_table :transfer_templates do |t|
      t.timestamps
      t.string :name
      t.string :transfer_class_name
      t.string :transfers, :limit => 1024
    end
  end

  def self.down
    drop_table :transfer_templates
  end
end
