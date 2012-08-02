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
