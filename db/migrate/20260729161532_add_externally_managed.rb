# frozen_string_literal: true
class AddExternallyManaged < ActiveRecord::Migration[8.0]
  def change
    add_column :studies, :externally_managed, :boolean, default: false, null: false,
                                                        comment: 'managed externally (e.g., by Sapio).'
  end
end
