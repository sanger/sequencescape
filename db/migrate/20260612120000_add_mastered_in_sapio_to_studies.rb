# frozen_string_literal: true

class AddMasteredInSapioToStudies < ActiveRecord::Migration[8.0]
  def change
    add_column :studies, :mastered_in_sapio, :boolean, default: false, null: false
  end
end
