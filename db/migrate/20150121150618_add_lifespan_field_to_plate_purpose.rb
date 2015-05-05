class AddLifespanFieldToPlatePurpose < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :plate_purposes, :lifespan, :integer, :null => true
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :plate_purposes, :lifespan
    end
  end
end
