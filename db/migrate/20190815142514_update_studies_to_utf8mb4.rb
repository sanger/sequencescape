# frozen_string_literal: true

# Update the studies table to utf8mb4
class UpdateStudiesToUtf8mb4 < ActiveRecord::Migration[5.1]
  include MigrationExtensions::EncodingChanges

  def change
    change_encoding('studies', from: 'latin1', to: 'utf8mb4')
  end
end
