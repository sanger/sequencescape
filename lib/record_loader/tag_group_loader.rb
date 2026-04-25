# frozen_string_literal: true

# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates or updates the specified tag groups.
  class TagGroupLoader < ApplicationRecordLoader
    config_folder 'tag_groups'

    # Creates or updates a TagGroup with the given section name and options.
    # - If the name for the TagGroup is not provided in options, it defaults to
    #   the YAML section name, which must be unique in config_folder.
    # - If the TagGroup does not have tags, it creates the associated tags based
    #   on the provided options.
    # - If the TagGroup exists and has a different adapter_type_id, it updates
    #   the adapter_type_id using the adapter_type_name provided in options.
    #
    # @param section_name [String] The default name for the TagGroup if not provided in options.
    # @param options [Hash] The attributes for the TagGroup.
    # @return [TagGroup] The found or newly created TagGroup record.
    # @raise [ActiveRecord::RecordInvalid] if creation or update fails validation.
    def create_or_update!(section_name, options)
      options['name'] ||= section_name
      resolve_adapter_type_id!(options)
      TagGroup
        .create_with(options.except('tags'))
        .find_or_create_by!(name: options['name'])
        .tap do |tag_group|
          create_tags(tag_group, options)
          update_adapter_type_id!(tag_group, options)
        end
    end

    private

    # Resolves the adapter_type_id for the TagGroup based on the provided
    # adapter_type_name in options. It deletes the adapter_type_name from
    # options and adds the corresponding adapter_type_id.
    #
    # @param options [Hash] The options hash containing 'adapter_type_name' key.
    # @return [void]
    def resolve_adapter_type_id!(options)
      adapter_type_name = options.delete('adapter_type_name')
      return unless adapter_type_name

      adapter_type = TagGroup::AdapterType.find_by!(name: adapter_type_name)
      options['adapter_type_id'] = adapter_type.id
    end

    # Creates tags for the given TagGroup based on the provided options if the
    # TagGroup does not already have tags. It expects the options to contain a
    # 'tags' hash where the keys are map_ids and the values are oligo sequences.
    #
    # @param tag_group [TagGroup] The TagGroup for which to create tags.
    # @param options [Hash] The options hash containing 'tags' key.
    # @return [void]
    def create_tags(tag_group, options)
      return unless tag_group.tags.empty?

      tags = options['tags'] || []
      tag_attributes = tags.map { |map_id, oligo| { map_id:, oligo: } }
      tag_group.tags.import(tag_attributes)
    end

    # Updates the adapter_type_id of the TagGroup if it differs from the
    # adapter_type_id in options. It expects options to contain an
    # 'adapter_type_id' key, resolved from 'adapter_type_name'.
    #
    # @param tag_group [TagGroup] The TagGroup to update.
    # @param options [Hash] The options hash containing 'adapter_type_id' key.
    # @return [void]
    def update_adapter_type_id!(tag_group, options)
      return if options['adapter_type_id'] == tag_group.adapter_type_id

      tag_group.update!(adapter_type_id: options['adapter_type_id'])
    end
  end
end
