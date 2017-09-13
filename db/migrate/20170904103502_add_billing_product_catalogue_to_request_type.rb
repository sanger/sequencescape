class AddBillingProductCatalogueToRequestType < ActiveRecord::Migration
  def change
    add_reference :request_types, :billing_product_catalogue, foreign_key: true, index: true
  end
end
