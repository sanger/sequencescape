# frozen_string_literal: true

# @see TagGroup::AdapterType
class AddAdapterTypeIdToTagGroup < ActiveRecord::Migration[5.1]
  def change
    add_reference :tag_groups, :adapter_type, foreign_key: { to_table: :tag_group_adapter_types }
  end
end
