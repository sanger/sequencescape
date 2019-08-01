# Rails migration
class ChangeExtractionColumnToLongText < ActiveRecord::Migration
  def change
    change_column :extraction_attributes, :attributes_update, :text, limit: 4294967295
  end
end
