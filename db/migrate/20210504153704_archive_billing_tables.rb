# frozen_string_literal: true

# Archive the billing tables to env_sequencescape_archive
class ArchiveBillingTables < ActiveRecord::Migration[5.2]
  include MigrationExtensions::DbTableArchiver

  def change
    check_archive!
    archive!('billing_items')
    archive!('billing_products')
    archive!('billing_product_catalogues')
  end
end
