# Programs group studies together in broader areas
class CreatePrograms < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      create_table :programs do |t|
        t.string :name
        t.timestamps
      end
      change_table :study_metadata do |t|
        t.references :program, index: true
      end
      # Default program
      Program.create!(name: 'General').save
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :study_metadata, :program_id
      drop_table :programs
    end
  end
end
