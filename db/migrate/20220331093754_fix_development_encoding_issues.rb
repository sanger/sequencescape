# frozen_string_literal: true

# The default database encoding for the development database was wrong
# We've fixed it up for newly created databases, but rather than forcing
# developers to rebuild their database we'll set up a special development
# only migration to keep things clean. This will:
# - Update the default encoding
# - Fix the incorrect encoding on any tables
# Production and UAT are both correct, so we don't try and do anything there to
# be safe.
class FixDevelopmentEncodingIssues < ActiveRecord::Migration[6.0]
  include MigrationExtensions::EncodingChanges

  def up
    say 'Checking Environment'
    if migrate?
      say "#{Rails.env} found, proceeding"
      update_encoding
      update_tables
    else
      say "#{Rails.env} found, skipping"
    end
  end

  def update_encoding
    execute("SET  @@character_set_database = 'utf8mb4', @@collation_database = 'utf8mb4_unicode_ci'")
  end

  def update_tables
    change_encoding('bkp_lab_events', from: 'utf8', to: 'utf8mb4')
    change_encoding('isndc_countries', from: 'utf8', to: 'utf8mb4')
    change_encoding('pick_lists', from: 'utf8', to: 'utf8mb4')
    change_encoding('racked_tubes', from: 'utf8', to: 'utf8mb4')
    change_encoding('sample_compounds_components', from: 'utf8', to: 'utf8mb4')
    change_encoding('tube_rack_statuses', from: 'utf8', to: 'utf8mb4')
  end

  def down
    if migrate?
      raise raise ActiveRecord::IrreversibleMigration, 'This is a remedial migration that shouldnot be reversed'
    end

    # We've not actually done anything, but something has obviously gone wrong elsewhere and someone is having a
    # bad day. Lets get out of their way and reverse nothing.
    say "This migration makes no changes in #{Rails.env}. " \
        'No schema changes have been made, but the migration has been removed from schema_migrations'
  end

  def migrate?
    Rails.env.local?
  end
end
