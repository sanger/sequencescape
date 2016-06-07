class AddColumnToTag2Layout < ActiveRecord::Migration
  def change
    add_column :tag2_layouts, :column, :integer
  end
end
