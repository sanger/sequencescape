class AddValidOptionsToPlateCreator < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :plate_creators, :valid_options, :text
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :plate_creators, :valid_options
    end
  end
end
