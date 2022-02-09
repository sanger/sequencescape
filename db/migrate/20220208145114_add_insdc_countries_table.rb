# frozen_string_literal: true

# As part of tightened restrictions on accessioning to the ENA, we will need
# to start sending country of origin information. These will need to match a
# controlled vocabulary of country names. We mirror the ENA list locally, in
# order to:
# 1) Denormalize our tables
# 2) Reduce dependency on the ENA outside of accessioning
class AddInsdcCountriesTable < ActiveRecord::Migration[6.0]
  def change
    create_table 'isndc_countries' do |t|
      t.string 'name', null: false, index: { unique: true }
      t.integer 'sort_priority', null: false, default: 0, index: true
      t.integer 'validation_state', null: false, default: 0, index: true

      t.timestamps
    end
  end
end
