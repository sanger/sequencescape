#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
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
