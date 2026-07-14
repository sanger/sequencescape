# frozen_string_literal: true
class IncreaseTagOligoLimit < ActiveRecord::Migration[8.0]
  def up
    change_column :tags, :oligo, :string, limit: 60
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Cannot revert oligo limit change'
  end
end
