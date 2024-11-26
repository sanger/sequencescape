class AddEbiLibrarySourceToSt < ActiveRecord::Migration[6.1]
  def change
    add_column :study_metadata, :ebi_library_source, :string, default: nil
  end
end
