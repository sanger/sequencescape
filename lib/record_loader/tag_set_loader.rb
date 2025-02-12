# frozen_string_literal: true

# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified TagSet if they are not present
  class TagSetLoader < ApplicationRecordLoader
    config_folder 'tag_sets'

    def create_or_update!(name, options)
      # It first creates or updates the
      # associated TagGroup records for `tag_group_id` and `tag2_group_id` if they
      # are not present. The TagGroup names are extracted from the options hash.

      tag_group_name = options.delete('tag_group_name')
      tag2_group_name = options.delete('tag2_group_name')

      tag_group = TagGroupLoader.new.create_or_update!(tag_group_name, options) if tag_group_name
      tag2_group = TagGroupLoader.new.create_or_update!(tag2_group_name, options) if tag2_group_name

      options[:tag_group_id] = tag_group.id if tag_group
      options[:tag2_group_id] = tag2_group.id if tag2_group

      TagSet.create_with(options).find_or_create_by!(name:)
    end
  end
end
