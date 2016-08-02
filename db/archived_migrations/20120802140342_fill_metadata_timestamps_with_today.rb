#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class FillMetadataTimestampsWithToday < ActiveRecord::Migration
  TABLES = [ :sample, :request, :plate, :study, :project, :lane, :pac_bio_library_tube ]

  def self.up
    ActiveRecord::Base.transaction do
      TABLES.each do |table|
        connection.execute("UPDATE #{table}_metadata SET created_at=now(),updated_at=now()")
      end
    end
  end

  def self.down
    # Nothing to do here
  end
end
