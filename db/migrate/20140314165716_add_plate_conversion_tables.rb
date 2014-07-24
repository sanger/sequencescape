class AddPlateConversionTables < ActiveRecord::Migration
  def self.up
    create_table 'plate_conversions' do |t|
      t.references :target,  :null => false
      t.references :purpose, :null => false
      t.references :user,    :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table 'plate_conversions'
  end
end
