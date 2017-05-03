class ChangeColumnAttributesUpdate < ActiveRecord::Migration
  def change
    change_column :extraction_attributes, :attributes_update, :longtext 
  end
end
