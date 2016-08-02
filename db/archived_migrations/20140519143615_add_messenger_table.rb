#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddMessengerTable < ActiveRecord::Migration
  def self.up
    create_table 'messengers' do |t|
      t.references :target, :polymorphic => true
      t.string 'root', :null=>false
      t.string 'template', :null=>false
      t.timestamps
    end
  end

  def self.down
    drop_table 'messengers'
  end
end
