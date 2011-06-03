class CreateAliquots < ActiveRecord::Migration
  def self.up
    create_table :aliquots do |t|
      t.references :receptacle
      t.references :sample
      t.references :tag

      t.timestamps
    end
  end

  def self.down
    drop_table :aliquots
  end
end
