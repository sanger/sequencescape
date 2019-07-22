# Rails migration
class CreateBillingItems < ActiveRecord::Migration[4.2]
  def change
    create_table :billing_items do |t|
      t.references :request, index: true, foreign_key: true
      t.string :project_cost_code
      t.string :units
      t.string :billing_product_code
      t.string :billing_product_name
      t.string :billing_product_description
      t.string :request_passed_date
      t.timestamp :reported_at

      t.timestamps null: false
    end
  end
end
