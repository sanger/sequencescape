# frozen_string_literal: true
class AddNumberOfSamplesPerPoolColumn < ActiveRecord::Migration[6.1]
  def change
    add_column :request_metadata, :number_of_samples_per_pool, :integer
  end
end
