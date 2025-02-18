# frozen_string_literal: true

# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified TagSet if they are not present
  class TagSetLoader < ApplicationRecordLoader
    config_folder 'tag_sets'

    ##
    # Creates or updates a TagSet with the given name and options.
    #
    # This method creates or updates a TagSet. It first checks for the existence
    # of the associated TagGroup records for `tag_group_id` and `tag2_group_id`.
    # If the TagGroup records are not present, it raises an error with a meaningful message.
    #
    # @param name [String] The name of the TagSet.
    # @param options [Hash] The options for creating or updating the TagSet.
    # @option options [String] :tag_group_name The name of the primary TagGroup.
    # @option options [String] :tag2_group_name The name of the secondary TagGroup.
    #
    # @return [TagSet] The created or updated TagSet.
    # @raise [ActiveRecord::RecordNotFound] If the TagGroup records are not found.

    def create_or_update!(name, options)
      tag_group = find_tag_group!(options.delete('tag_group_name'))
      tag2_group = find_tag_group!(options.delete('tag2_group_name'))

      options[:tag_group_id] = tag_group.id if tag_group
      options[:tag2_group_id] = tag2_group.id if tag2_group

      TagSet.create_with(options).find_or_create_by!(name:)
    end

    private

    def find_tag_group!(tag_group_name)
      return unless tag_group_name

      TagGroup.find_by!(name: tag_group_name)
    rescue ActiveRecord::RecordNotFound
      raise ActiveRecord::RecordNotFound, "TagGroup with name '#{tag_group_name}' not found"
    end
  end
end
