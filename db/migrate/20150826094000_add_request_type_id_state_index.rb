# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class AddRequestTypeIdStateIndex < ActiveRecord::Migration
  def self.up
    add_index :requests, [:request_type_id, :state], :name => 'request_type_id_state_index'
  end

  def self.down
    remove_index :requests, 'request_type_id_state_index'
  end
end
