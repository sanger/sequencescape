# frozen_string_literal: true
# Cherrypick strategies to use with a plate were serialized in cherrypick_filters
# They have been unused for a few years.
class RemoveCherrypickStrategyColumn < ActiveRecord::Migration[5.1]
  def change
    remove_column :plate_purposes, 'cherrypick_filters', :string
  end
end
