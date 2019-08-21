# Rails migration
class AddCategoryToBaitLibraryTypes < ActiveRecord::Migration[5.1]
  def change
    add_column :bait_library_types, :category, :integer
  end
end
