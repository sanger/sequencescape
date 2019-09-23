# frozen_string_literal: true

# Update the samples table to ut8mb4
class UpdateSamplesToUtf8mb4 < ActiveRecord::Migration[5.1]
  include MigrationExtensions::EncodingChanges

  def change
    change_encoding('samples', from: 'latin1', to: 'utf8mb4')
  end
end
