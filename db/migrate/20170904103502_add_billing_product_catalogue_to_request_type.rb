# Rails migration
class AddBillingProductCatalogueToRequestType < ActiveRecord::Migration[4.2]
  def change
    add_reference :request_types, :billing_product_catalogue, foreign_key: true, index: true
  end
end
