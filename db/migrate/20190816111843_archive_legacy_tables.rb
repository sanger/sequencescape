# frozen_string_literal: true

# Before we migrate all our tables to utf8mb4
# lets clean up the tables we no longer require
# We archive them, rather than dropping them completely
class ArchiveLegacyTables < ActiveRecord::Migration[5.1]
  include MigrationExtensions::DbTableArchiver

  def change
    check_archive!
    archive!('archived_properties')
    archive!('asset_descriptors_backup')
    archive!('attachments')
    archive!('audits')
    archive!('billing_events')
    archive!('depricated_attempts')
    archive!('documents_shadow')
    archive!('quotas_bkp')
    archive!('request_quotas_bkp')
    archive!('study_relation_types')
    archive!('study_relations')
    archive!('study_samples_backup')
    archive!('task_request_types')
  end
end
