# frozen_string_literal: true

class RemoveDefaultLocationFromPlatePurpose < ActiveRecord::Migration[5.1]
  def change
    remove_column :plate_purposes, :default_location_id, :integer
  end
end
