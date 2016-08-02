#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddPreCapturePlexGroupToRequest < ActiveRecord::Migration
  def self.up

    create_table :pre_capture_pool_pooled_requests do |t|
      t.references  :pre_capture_pool, :null => false
      t.references  :request, :null => false
    end

    add_index :pre_capture_pool_pooled_requests, [:request_id], :name => "request_id_should_be_unique", :unique => true

  end

  def self.down
    drop_table :pre_capture_pool_pooled_requests
  end
end
