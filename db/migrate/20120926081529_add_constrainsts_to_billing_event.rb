class AddConstrainstsToBillingEvent < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      change_column(:billing_events, :request_id, :integer, :null => false)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      change_column(:billing_events, :request_id, :integer, :null => true)
    end
  end
end
