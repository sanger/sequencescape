# frozen_string_literal: true

# Autogenerated migration to convert documents to utf8mb4
class MigrateDocumentsToUtf8mb4 < ActiveRecord::Migration[5.1]
  include MigrationExtensions::EncodingChanges

  def change
    change_encoding('documents', from: 'latin1', to: 'utf8mb4')
  end
end
