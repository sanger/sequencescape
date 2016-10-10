# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class AddQcReportTable < ActiveRecord::Migration

  require './lib/foreign_key_constraint'
  extend ForeignKeyConstraint

  def self.up
    create_table :qc_reports do |t|
      t.integer :study_id,            :null => false
      t.integer :product_criteria_id, :null => false
      t.boolean :exclude_existing,    :null => false
      t.string  :state
      t.timestamps
    end

    add_constraint('qc_reports','studies')
  end

  def self.down
    drop_constraint('qc_reports','studies')
    drop_table :qc_reports
  end
end
