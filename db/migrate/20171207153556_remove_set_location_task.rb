# frozen_string_literal: true

class RemoveSetLocationTask < ActiveRecord::Migration[5.1] # rubocop:todo Style/Documentation
  def up
    Task.where(sti_type: 'SetLocationTask').delete_all
  end

  def down; end
end
