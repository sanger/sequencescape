# frozen_string_literal: true
class DropPickLists < ActiveRecord::Migration[8.1]
  def change
    drop_table :pick_lists
  end
end
