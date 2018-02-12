class AddColumnsToAkerProducts < ActiveRecord::Migration[5.1]
  def change
    add_column :aker_products, :product_version, :integer, default: 1
    add_column :aker_products, :availability, :boolean, default: true
    add_column :aker_products, :requested_biomaterial_type, :string
    add_column :aker_products, :product_class, :string
  end
end
