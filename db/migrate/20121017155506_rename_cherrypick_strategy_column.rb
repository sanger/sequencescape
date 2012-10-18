class RenameCherrypickStrategyColumn < ActiveRecord::Migration
  def self.up
    rename_column(:plate_purposes, :cherrypick_strategy, :cherrypick_filters)
  end

  def self.down
    rename_column(:plate_purposes, :cherrypick_filters, :cherrypick_strategy)
  end
end
