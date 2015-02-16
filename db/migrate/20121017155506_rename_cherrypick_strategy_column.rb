#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class RenameCherrypickStrategyColumn < ActiveRecord::Migration
  def self.up
    rename_column(:plate_purposes, :cherrypick_strategy, :cherrypick_filters)
  end

  def self.down
    rename_column(:plate_purposes, :cherrypick_filters, :cherrypick_strategy)
  end
end
