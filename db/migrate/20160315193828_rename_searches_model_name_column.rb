# This is not the model for the search, but for what it's finding.
class RenameSearchesModelNameColumn < ActiveRecord::Migration
  def change
    rename_column :searches, :model_name, :target_model_name
  end
end
