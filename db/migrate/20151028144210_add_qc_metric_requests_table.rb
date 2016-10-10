# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class AddQcMetricRequestsTable < ActiveRecord::Migration
  require './lib/foreign_key_constraint'
  extend ForeignKeyConstraint

  def self.up
    create_table :qc_metric_requests do |t|
      t.references :qc_metric, :null => false
      t.references :request, :null => false
      t.timestamps
    end

    add_constraint('qc_metric_requests','qc_metrics')
    add_constraint('qc_metric_requests','requests')
  end

  def self.down
    drop_constraint('qc_metric_requests','qc_metrics')
    drop_constraint('qc_metric_requests','requests')
    drop_table :qc_metric_requests
  end
end
