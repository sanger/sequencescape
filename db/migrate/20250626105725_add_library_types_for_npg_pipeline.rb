# frozen_string_literal: true

class AddLibraryTypesForNpgPipeline < ActiveRecord::Migration[7.1]
  def up
    LibraryType.find_or_create_by(name: 'SPLADE-seq')
    LibraryType.find_or_create_by(name: 'Spatial Genomics Dev')
  end

  def down
    LibraryType.find_by(name: 'SPLADE-seq')&.destroy
    LibraryType.find_by(name: 'Spatial Genomics Dev')&.destroy
  end
end
