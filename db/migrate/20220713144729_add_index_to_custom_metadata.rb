# frozen_string_literal: true

# Adds an index to the 'key' and 'value' fields on custom_metadata table.
# We added a search function in DPL-395-2, on the advanced_search page.
# This should make it nice and quick.
class AddIndexToCustomMetadata < ActiveRecord::Migration[6.0]
  def change
    add_index :custom_metadata, %i[key value]
  end
end
