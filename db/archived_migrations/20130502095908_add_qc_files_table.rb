#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddQcFilesTable < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      create_table :qc_files do |t|
        t.references :asset, :polymorphic => true
        t.integer 'size'
        t.string 'content_type'
        t.string 'filename'
        t.referenced :db_file
        t.timestamps
      end
    end
  end

  def self.down
    drop_table :qc_files
  end
end
