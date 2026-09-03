# frozen_string_literal: true
class AddExternallyManaged < ActiveRecord::Migration[8.0]
  def change
    comment = 'Indicates whether the study is managed externally (e.g., by Sapio).'
    add_column :studies, :externally_managed, :boolean, default: false, null: false, comment: comment
  end
end
