# frozen_string_literal: true
class AddEbiRequirementFieldsToStudyMetadata < ActiveRecord::Migration[6.1]
  def change
    def change
      add_column :study_metadata, :ebi_library_strategy, :string, default: nil
      add_column :study_metadata, :ebi_library_source, :string, default: nil
      add_column :study_metadata, :ebi_library_selection, :string, default: nil
    end
  end
end
