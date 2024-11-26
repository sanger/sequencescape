class AddEbiLibraryStrategyToStudayMetadata < ActiveRecord::Migration[6.1]
  def change
    add_column :study_metadata, :ebi_library_strategy, :string, default: nil
  end
end
