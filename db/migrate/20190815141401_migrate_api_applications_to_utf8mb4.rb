# frozen_string_literal: true

# Small table, mostly stepping through low impact stuff
class MigrateApiApplicationsToUtf8mb4 < ActiveRecord::Migration[5.1]
  include MigrationExtensions::EncodingChanges

  def change
    change_encoding('api_applications', from: 'latin1', to: 'utf8mb4')
  end
end
