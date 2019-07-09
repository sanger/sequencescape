# frozen_string_literal: true

# Remove the more receptacle like columns on labware
class DropExcessLabwareColumns < ActiveRecord::Migration[4.2]
  def change
    remove_column 'labware', 'value', :string,                   limit: 255
    remove_column 'labware', 'qc_state', :string,                limit: 20
    remove_column 'labware', 'map_id', :integer, limit: 4
    remove_column 'labware', 'resource', :boolean
    # Exposed, but barely used. I think we can safely drop this.
    # remove_column 'labware', 'public_name', :string, limit: 255
    remove_column 'labware', 'archive', :boolean
    remove_column 'labware', 'external_release', :boolean
    remove_column 'labware', 'volume', :decimal,                                precision: 10, scale: 2
    remove_column 'labware', 'concentration', :decimal,                         precision: 18, scale: 8
    remove_column 'labware', 'legacy_sample_id', :integer,        limit: 4
    remove_column 'labware', 'legacy_tag_id', :integer,           limit: 4
    remove_column 'labware', 'barcode_bkp', :string,                   limit: 255
    remove_column 'labware', 'barcode_prefix_id_bkp', :integer,        limit: 4
    remove_column 'labware', 'closed', :boolean, default: false
  end
end
