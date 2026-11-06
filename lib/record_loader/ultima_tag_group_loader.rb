# frozen_string_literal: true

# Handles loading of Ultima data for tag groups and their tags.
module RecordLoader
  # Creates the UltimaTagGroup of each tag group named in the files, and the
  # UltimaTag of each of its tags, unless they exist already.
  class UltimaTagGroupLoader < ApplicationRecordLoader
    config_folder 'ultima_tag_groups'

    # @param section_name [String] the name of an existing tag group, unless
    #   options give 'name'
    # @param options [Hash] 'name' (optional) of an existing tag group,
    #   'barcode_plate_num', and 'ultima_tags': the attributes of each
    #   tag's UltimaTag, keyed by the tag's map_id (its index in the tag
    #   group, not a well's Map)
    # @raise [ActiveRecord::RecordNotFound] if the tag group doesn't exist
    # @raise [ArgumentError] if the tag map_ids aren't exactly the group's
    def create_or_update!(section_name, options)
      tag_group_name = options['name'] || section_name # name if provided
      tag_group = TagGroup.find_by!(name: tag_group_name)
      UltimaTagGroup
        .create_with(barcode_plate_num: options['barcode_plate_num'])
        .find_or_create_by!(tag_group:)
      create_ultima_tags(tag_group, options.fetch('ultima_tags'))
    end

    private

    # Creates the UltimaTag of each tag in the group, unless it exists.
    # Every tag of the group must be given, and only those, by its map_id
    # (its index in the tag group, not a well's Map).
    def create_ultima_tags(tag_group, ultima_tags)
      tags = tag_group.tags.index_by(&:map_id)
      check_map_ids!(tags.keys, ultima_tags.keys)
      ultima_tags.each do |map_id, attributes|
        UltimaTag.create_with(attributes).find_or_create_by!(tag: tags[map_id])
      end
    end

    def check_map_ids!(group_map_ids, given_map_ids)
      missing = group_map_ids - given_map_ids
      unknown = given_map_ids - group_map_ids
      return if missing.empty? && unknown.empty?

      raise ArgumentError,
            "tag map_ids not given: #{missing}, " \
            "not in the tag group: #{unknown}"
    end
  end
end
