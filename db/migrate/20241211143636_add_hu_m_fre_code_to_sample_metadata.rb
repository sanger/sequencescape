# frozen_string_literal: true
class AddHuMFreCodeToSampleMetadata < ActiveRecord::Migration[7.0]
  def change
    add_column :sample_metadata, :huMFre_code, :string, limit: 16
  end
end
