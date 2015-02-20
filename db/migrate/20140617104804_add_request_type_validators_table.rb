#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddRequestTypeValidatorsTable < ActiveRecord::Migration
  def self.up
    create_table(:request_type_validators) do |t|
      t.references :request_type,   :null => false
      t.string     :request_option, :null => false
      t.text       :valid_options,  :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :request_type_validators
  end
end
