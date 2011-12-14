class MultipleBillingEvents < ActiveRecord::Migration
  def self.up
    change_column :billing_events, :quantity, :float
  end

  def self.down
    change_column :billing_events, :quantity, :integer
  end
end
