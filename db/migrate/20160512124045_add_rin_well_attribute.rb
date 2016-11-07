class AddRinWellAttribute < ActiveRecord::Migration
  def up
    ActiveRecord::Base.transaction do
      add_column :well_attributes, :rin, :float
    end
  end

  def down
    ActiveRecord::Base.transaction do
      remove_column :well_attributes, :rin
    end
  end
end
