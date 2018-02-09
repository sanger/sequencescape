class AddCatalogueToAkerProducts < ActiveRecord::Migration[5.1]
  def change
    add_reference :aker_products, :aker_catalogue, index: true
  end
end
