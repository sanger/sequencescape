#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

class AddMessengerCreatorsTable < ActiveRecord::Migration

  require './lib/foreign_key_constraint'
  extend ForeignKeyConstraint

  def self.up
    ActiveRecord::Base.transaction do
      create_table :messenger_creators do |t|
        t.string  :template,   :null => false
        t.string  :root,       :null => false
        t.integer :purpose_id, :null => false
        t.timestamps
      end

      add_constraint('messenger_creators','plate_purposes', :as=>'purpose_id')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      drop_constraint('messenger_creators','plate_purposes', :as=>'purpose_id')
      drop_table :messenger_creators
    end
  end
end
