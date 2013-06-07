class IncreaseRequestTypesKeyLengthTo100 < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      change_column 'request_types', 'key', :string, :limit => 100
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      change_column 'request_types', 'key', :string, :limit => 50
    end
  end
end
