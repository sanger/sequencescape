# frozen_string_literal: true

# Removes plates from receptacles
class ClearLabwareFromReceptacles < ActiveRecord::Migration[4.2]
  # Migration specific class to isolate us from external code-changes
  class Receptacle < ApplicationRecord
    self.table_name = 'receptacles'
  end

  def change
    Receptacle.where(sti_type: ['Plate', *Plate.descendants.map(&:name)]).destroy_all
  end
end
