# frozen_string_literal: true
class AddExternallyManagedToStudies < ActiveRecord::Migration[8.0]
  def change
    add_column :studies, :externally_managed, :boolean, default: false, null: false
  end
end
