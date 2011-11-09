class AddStudyIndexOnAliquots < ActiveRecord::Migration
  def self.up
    add_index(:aliquots, :study_id)
  end

  def self.down
    remove_index(:aliquots, :column => :study_id)
  end
end
