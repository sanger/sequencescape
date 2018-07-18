# frozen_string_literal: true

# Assists in finding of study requests through aliquots
class AddStudyReceptacleIndexToAliquots < ActiveRecord::Migration[5.1]
  def change
    add_index :aliquots, [:study_id, :receptacle_id]
  end
end
