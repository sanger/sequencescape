class AddGigabasesExpectedField < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :request_metadata, :gigabases_expected, :float
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :request_metadata, :gigabases_expected
    end
  end
end
