class ArchiveUnwantedTables < ActiveRecord::Migration
  def self.up
    DbTableArchiver.archive!('db_files_shadow')
    DbTableArchiver.archive!('sample_manifests_shadow')
    DbTableArchiver.archive!('study_reports_shadow')
    DbTableArchiver.archive!('plate_volumes_shadow')
  end

  def self.down
    DbTableArchiver.restore!('db_files_shadow')
    DbTableArchiver.restore!('sample_manifests_shadow')
    DbTableArchiver.restore!('study_reports_shadow')
    DbTableArchiver.restore!('plate_volumes_shadow')
  end
end
