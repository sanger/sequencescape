# frozen_string_literal: true

# The families table is removed in db/migrate/20190719125128_drop_families_table.rb
class RemoveFamilyIdColumns < ActiveRecord::Migration[5.1]
  def change
    remove_column :descriptors, :family_id, :integer
  end
end
