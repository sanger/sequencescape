# frozen_string_literal: true
class AddExternallyManagedToSamples < ActiveRecord::Migration[8.1]
  def change
    comment = 'Indicates whether the sample is managed externally (e.g., by Sapio).'
    add_column :samples, :externally_managed, :boolean, default: false, null: false, comment: comment
  end
end
