class AddCherrypickingStrategyToPlatePurpose < ActiveRecord::Migration
  def self.up
    add_column(:plate_purposes, :cherrypick_strategy, :string)
  end

  def self.down
    remove_column(:plate_purposes, :cherrypick_strategy)
  end
end
