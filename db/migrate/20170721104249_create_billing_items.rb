class CreateBillingItems < ActiveRecord::Migration
  def change
    create_table :billing_items do |t|
      t.references :request, index: true, foreign_key: true
      t.string :project_cost_code
      t.string :units
      t.string :fin_product_code
      t.string :fin_product_description
      t.string :request_passed_date
      t.timestamp :reported_at

      t.timestamps null: false
    end
  end
end
