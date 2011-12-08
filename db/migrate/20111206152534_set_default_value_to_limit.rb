class SetDefaultValueToLimit < ActiveRecord::Migration
  def self.up
    change_column_default :quotas, :limit, 0
  end

  def self.down
    change_column_default :quotas, :limit, nil
  end
end
