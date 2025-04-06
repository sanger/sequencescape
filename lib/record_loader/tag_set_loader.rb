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
    # If the TagGroup records are not present, it logs an error message and returns.
    #
    # @param name [String] The name of the TagSet.
    # @param options [Hash] The options for creating or updating the TagSet.
    # @option options [String] :tag_group_name The name of the primary TagGroup.
    # @option options [String] :tag2_group_name The name of the secondary TagGroup.
    #
    # @return [TagSet, nil] The created or updated TagSet, or nil if the TagGroup records are not found.

    def create_or_update!(name, options)
      tag_group_name = options.delete('tag_group_name')
      tag2_group_name = options.delete('tag2_group_name')

      tag_group = find_tag_group!(tag_group_name, name)
      return nil if tag_group.nil?
      tag2_group = find_tag_group!(tag2_group_name, name) if tag2_group_name

      options[:tag_group_id] = tag_group.id
      options[:tag2_group_id] = tag2_group.id if tag2_group

      TagSet.create_with(options).find_or_create_by!(name:)
    end

    private

    ##
    # Finds a TagGroup by name and raises an error if not found.
    #
    # This method attempts to find a TagGroup by its name. If the TagGroup is not found,
    # it raises an error indicating that the TagGroup was not found.
    #
    # @param tag_group_name [String] The name of the TagGroup to find.
    # @param tag_set_name [String] The name of the TagSet being created or updated.
    #
    # @return [TagGroup] The found TagGroup.
    # @raise [ActiveRecord::RecordNotFound] If the TagGroup is not found.
    def find_tag_group!(tag_group_name, tag_set_name)
      return unless tag_group_name
      TagGroup.find_by!(name: tag_group_name)
    rescue ActiveRecord::RecordNotFound
      message =
        "TagSet '#{tag_set_name}' creation or update failed " \
          "because TagGroup with name '#{tag_group_name}' was not found"
      raise ActiveRecord::RecordNotFound, message if Rails.env.production?
      Rails.logger.warn(message) # Log a warning in not in production
      nil
    end
  end
end
