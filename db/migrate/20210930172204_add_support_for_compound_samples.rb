# frozen_string_literal: true

# Add a join table to allow samples to be compounds made up of component samples.
class AddSupportForCompoundSamples < ActiveRecord::Migration[6.0]
  def change
    create_table 'sample_compounds_components' do |t|
      t.integer 'compound_sample_id', null: false
      t.integer 'component_sample_id', null: false
      t.integer 'asset_id', null: true
      t.integer 'target_asset_id', null: true

      t.timestamps
    end
  end
end
