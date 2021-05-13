# frozen_string_literal: true

# Remove foreign keys to tables we're about to archive
class RemoveBillingForeignKeys < ActiveRecord::Migration[5.2]
  def change
    remove_foreign_key 'request_types', 'billing_product_catalogues'
    remove_foreign_key 'billing_items', 'requests'
    remove_foreign_key 'requests', 'billing_products'
  end
end
