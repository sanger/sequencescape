class AddTimestampsToAllMetadataTables < ActiveRecord::Migration
  TABLES = [ :sample, :request, :plate, :study, :project, :lane, :pac_bio_library_tube ]

  def self.up
    alter_tables do
      add_column(:created_at, :datetime)
      add_column(:updated_at, :datetime)
    end
  end

  def self.down
    alter_tables do
      remove_column(:created_at)
      remove_column(:updated_at)
    end
  end

  def self.alter_tables(&block)
    TABLES.each do |table|
      alter_table("#{table}_metadata", &block)
    end
  end
end
