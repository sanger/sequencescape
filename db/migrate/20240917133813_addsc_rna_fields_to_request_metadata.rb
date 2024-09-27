# frozen_string_literal: true
class AddscRnaFieldsToRequestMetadata < ActiveRecord::Migration[6.1]
  def change
    add_column :request_metadata, :number_of_samples_per_pool, :integer, null: true
    add_column :request_metadata, :cells_per_chip_well, :integer, null: true
  end
end
