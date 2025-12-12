# frozen_string_literal: true
#
# Migration to create the ultima_globals table to store the values that are
# used in the global section of Ultima sample sheets.
class CreateUltimaGlobals < ActiveRecord::Migration[7.1]
  def change
    create_table :ultima_globals do |t|
      t.string :name
      t.string :application
      t.string :sequencing_recipe
      t.string :analysis_recipe

      t.timestamps
    end
  end
end
