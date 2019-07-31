# frozen_string_literal: true

# Removes the labwarey columns on receptacle
class DropExcessReceptacleColumns < ActiveRecord::Migration[4.2]
  def change
    remove_column 'receptacles', 'name', :string,                    limit: 255
    remove_column 'receptacles', 'value', :string,                   limit: 255
    remove_column 'receptacles', 'size', :integer, limit: 4
    remove_column 'receptacles', 'barcode_bkp', :string,                   limit: 255
    remove_column 'receptacles', 'barcode_prefix_id_bkp', :integer,        limit: 4
    remove_column 'receptacles', 'archive', :boolean
    remove_column 'receptacles', 'two_dimensional_barcode', :string, limit: 255
    remove_column 'receptacles', 'plate_purpose_id', :integer,        limit: 4
    remove_column 'receptacles', 'legacy_sample_id', :integer,        limit: 4
    remove_column 'receptacles', 'legacy_tag_id', :integer,           limit: 4
  end
end
