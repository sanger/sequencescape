class AddBillingProductToRequests < ActiveRecord::Migration
  def change
    add_reference :requests, :billing_product, index: true, foreign_key: true
  end
end
