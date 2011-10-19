class MakeDbFilesPolymorphic < ActiveRecord::Migration
  def self.up
    change_table :db_files do |t|
      t.column :owner_type, :string, :default => 'Document'
      t.rename :document_id, :owner_id
    end
  end

  def self.down
    change_table :db_files do |t|
      t.remove :owner_type
      t.rename :owner_id, :document_id
    end
  end
end
