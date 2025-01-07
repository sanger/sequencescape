# frozen_string_literal: true
class AddEbiLibraryStrategyToStudyMetadata < ActiveRecord::Migration[6.1]
  def change
    add_column :study_metadata, :ebi_library_strategy, :string, default: nil
  end
end

class AddEbiLibrarySourceToStudyMetadata < ActiveRecord::Migration[6.1]
  def change
    add_column :study_metadata, :ebi_library_source, :string, default: nil
  end
end

class AddEbiLibrarySelectionToStudyMetadata < ActiveRecord::Migration[6.1]
  def change
    add_column :study_metadata, :ebi_library_selection, :string, default: nil
  end
end
