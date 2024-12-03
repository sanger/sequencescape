# frozen_string_literal: true
class AddEbiLibrarySelectionToSt < ActiveRecord::Migration[6.1]
  def change
    add_column :study_metadata, :ebi_library_selection, :string, default: nil
  end
end
