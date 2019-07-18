# Rails migration
class AddBillingProductToRequests < ActiveRecord::Migration[4.2]
  def change
    add_reference :requests, :billing_product, index: true, foreign_key: true
  end
end
