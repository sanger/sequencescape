class AddBillableToRequestTypes < ActiveRecord::Migration
  def self.up
    add_column :request_types, :billable, :boolean, :default => false
  end

  def self.down
    remove_column :request_types, :billable
  end
end
