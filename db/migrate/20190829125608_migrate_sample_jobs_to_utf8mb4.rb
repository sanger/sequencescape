# frozen_string_literal: true

# Autogenerated migration to convert sample_jobs to utf8mb4
class MigrateSampleJobsToUtf8mb4 < ActiveRecord::Migration[5.1]
  include MigrationExtensions::EncodingChanges

  def change
    change_encoding('sample_jobs', from: 'latin1', to: 'utf8mb4')
  end
end
