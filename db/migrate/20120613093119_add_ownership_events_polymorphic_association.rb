class AddOwnershipEventsPolymorphicAssociation < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      alter_table(:plate_owners) do |t|
        t.add_column :eventable_id, :integer, :null => false
        t.add_column :eventable_type, :string, :null => false
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      alter_table(:plate_owners) do |t|
        t.remove_column :eventable_id
        t.remove_column :eventable_type
      end
    end
  end
end
