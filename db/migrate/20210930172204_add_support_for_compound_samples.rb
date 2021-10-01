# frozen_string_literal: true

# Add a join table to allow samples to be parents and children of each other.
class AddSupportForCompoundSamples < ActiveRecord::Migration[6.0]
  def change
    create_table 'compound_samples' do |t|
      t.integer 'parent_id', null: false
      t.integer 'child_id', null: false

      t.timestamps
    end
  end
end
