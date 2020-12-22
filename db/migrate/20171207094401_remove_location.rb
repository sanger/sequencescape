# frozen_string_literal: true

class RemoveLocation < ActiveRecord::Migration[5.1] # rubocop:todo Style/Documentation
  def change
    drop_table :locations do |t|
      t.string :name
    end
  end
end
