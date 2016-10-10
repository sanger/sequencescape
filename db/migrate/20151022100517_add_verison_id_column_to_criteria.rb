# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class AddVerisonIdColumnToCriteria < ActiveRecord::Migration
  def self.up
    add_column :product_criteria, :version, :integer
    add_index :product_criteria, [:product_id,:stage,:version], unique: true
  end

  def self.down
    remove_index :product_criteria, [:product_id,:stage,:version]
    remove_column :product_criteria, :version
  end
end
