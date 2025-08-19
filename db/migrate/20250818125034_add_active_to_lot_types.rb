# frozen_string_literal: true
class AddActiveToLotTypes < ActiveRecord::Migration[7.1]
  def change
    add_column :lot_types, :active, :boolean, default: true
  end
end
