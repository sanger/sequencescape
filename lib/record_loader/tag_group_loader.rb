# frozen_string_literal: true

# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified tag groups if they are not present
  class TagGroupLoader < ApplicationRecordLoader
    config_folder 'tag_groups'

    def create_or_update!(name, options)
      tags = options.delete('tags') || []

      TagGroup
        .create_with(options)
        .find_or_create_by!(name:)
        .tap do |tag_group|
          tag_attributes = tags.map { |map_id, oligo| { map_id:, oligo: } }
          tag_group.tags.import(tag_attributes) if tag_group.tags.empty?
        end
    end
  end
end
