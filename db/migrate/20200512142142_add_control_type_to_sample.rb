# frozen_string_literal: true

# Add 'control_type' to sample to store whether a control is positive or negative
# Works in conjunction with the 'control' field
class AddControlTypeToSample < ActiveRecord::Migration[5.2]
  def change
    add_column :samples, :control_type, :integer
  end
end
