class CreateAkerCatalogues < ActiveRecord::Migration[5.1]
  def change
    create_table :aker_catalogues do |t|
      t.string :pipeline
      t.string :lims_id
      t.timestamps null: false
    end
  end
end
