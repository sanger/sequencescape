#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class MarkPipelinesInactive < ActiveRecord::Migration
  def self.change_active_status(state)
    Pipeline.update_all(
      "active = #{state.inspect.upcase}", [
        'name IN (?)', [
          'MX Library creation',
          'Manual Quality Control',
          'Quality Control'
        ]
      ]
    )
  end

  def self.up
    change_active_status(false)
  end

  def self.down
    change_active_status(true)
  end
end
