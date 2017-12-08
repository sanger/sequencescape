class RemoveSetLocationTask < ActiveRecord::Migration[5.1]
  def up
    Task.where(sti_type: 'SetLocationTask').destroy_all
  end

  def down; end
end
