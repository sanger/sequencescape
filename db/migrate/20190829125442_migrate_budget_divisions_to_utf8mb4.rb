# frozen_string_literal: true

# Autogenerated migration to convert budget_divisions to utf8mb4
class MigrateBudgetDivisionsToUtf8mb4 < ActiveRecord::Migration[5.1]
  include MigrationExtensions::EncodingChanges

  def change
    change_encoding('budget_divisions', from: 'latin1', to: 'utf8mb4')
  end
end
