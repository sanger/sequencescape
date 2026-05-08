# frozen_string_literal: true
class AddDeprecatedFieldsToPlatePurposes < ActiveRecord::Migration[8.0]
  def change
    add_column :plate_purposes, :deprecated, :boolean, default: false, null: false
    add_column :plate_purposes, :deprecated_at, :datetime
  end
end
