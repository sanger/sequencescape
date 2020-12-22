# frozen_string_literal: true

class RemoveLocationAssociations < ActiveRecord::Migration[5.1] # rubocop:todo Style/Documentation
  def change
    drop_table :location_associations do |t|
      t.integer :locatable_id
      t.integer :location_id
    end
  end
end
