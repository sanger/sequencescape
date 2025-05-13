# frozen_string_literal: true

class ChangeFlipperGatesValueToText < ActiveRecord::Migration[7.1]
  def up
    if index_exists?(:flipper_gates, %i[feature_key key value], unique: true)
      remove_index(:flipper_gates, %i[feature_key key value], unique: true)
    end
    change_column :flipper_gates, :value, :text
    add_index :flipper_gates, %i[feature_key key value], unique: true, length: { value: 255 }
  end

  def down
    change_column :flipper_gates, :value, :string
    remove_index(:flipper_gates, %i[feature_key key value], unique: true)
  end
end
