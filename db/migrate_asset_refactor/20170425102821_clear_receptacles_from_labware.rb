# frozen_string_literal: true

# Removes wells from labware
class ClearReceptaclesFromLabware < ActiveRecord::Migration[4.2]
  # Migration specific class to isolate us from external code-changes
  class Labware < ApplicationRecord
    self.table_name = 'labware'
  end

  def change
    Labware.where(sti_type: ['Well']).destroy_all
  end
end
