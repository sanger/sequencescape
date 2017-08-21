class AddQcFileIndex < ActiveRecord::Migration
  def change
    add_foreign_key :qc_files, :assets
  end
end
