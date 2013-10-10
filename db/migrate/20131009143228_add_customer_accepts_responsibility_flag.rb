class AddCustomerAcceptsResponsibilityFlag < ActiveRecord::Migration
  def self.up
    add_column :request_metadata, :customer_accepts_responsibility, :boolean
  end

  def self.down
    remove_column :request_metadata, :customer_accepts_responsibility
  end
end
