# frozen_string_literal: true

# remove the Aker tables

# rubocop:disable Rails/ReversibleMigration
# I see no reason to make this reversible.
class DropAkerTables < ActiveRecord::Migration[6.0]
  def change
    drop_table :aker_containers
    drop_table :aker_jobs
    drop_table :sample_jobs
  end
end
# rubocop:enable Rails/ReversibleMigration