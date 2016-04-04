#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
#
class AddIndexTagLayoutTable < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      create_table :tag2_layouts do |t|
        t.integer  :tag_id
        t.integer  :plate_id
        t.integer  :user_id
        t.datetime :created_at
        t.datetime :updated_at
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      drop_table :tag2_layouts
    end
  end
end
