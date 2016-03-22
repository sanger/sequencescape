#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

class UpdateQcMetricsStateColumn < ActiveRecord::Migration
  require './lib/foreign_key_constraint'
  extend ForeignKeyConstraint

  def self.up
    change_column :qc_metrics, :qc_decision, :string, :null => false
  end

  def self.down
    change_column :qc_metrics, :qc_decision, :boolean, :null => false
  end
end
