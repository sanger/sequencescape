# frozen_string_literal: true
module RecordLoader
  # == Schema Information
  #
  # Table name: your_table_name
  #
  #  id            :integer          not null, primary key, auto-increment
  #  name          :string(255)      not null
  #  valid_options :text             utf8mb4, optional (e.g., serialized JSON)
  #  created_at    :datetime         optional
  #  updated_at    :datetime         optional
  #
  # Notes:
  # - Text fields use UTF-8 (utf8mb4) encoding.
  # - Timestamps are nullable and can be automatically managed with `t.timestamps` in migrations.
  # - Plate::Creator has a has-many relationship with Plate::Creator::PurposeRelationship
  #   and `Plate::Creator::ParentPurposeRelationship`
  #
  # Configuration for Stock RNA Plate
  #
  # name: 'Stock RNA Plate'
  #
  # valid_options:
  #   valid_dilution_factors:
  #     - 1.0
  #
  # purposes:
  #   - 'Stock RNA Plate'
  #
  # parent_purposes:
  #   (none specified)
  class PlateCreatorLoader < ApplicationRecordLoader
    config_folder 'plate_creators'

    # Creates or updates a Plate::Creator record within a database transaction.
    #
    # If a Plate::Creator with the given name does not exist, it is created and associated
    # with the specified purposes and parent purposes. If it exists, no changes are made.
    #
    # @param name [String] The name of the Plate::Creator.
    # @param options [Hash] Options hash containing purposes and parent_purposes arrays.
    # @return [Plate::Creator] The found or newly created Plate::Creator.
    def create_or_update!(name, options)
      ActiveRecord::Base.transaction do
        create_plate_creator_if_does_not_exist(name, options)
      end
    end

    # Finds or creates a Plate::Creator by name, and assigns purposes and parent purposes.
    #
    # If the Plate::Creator does not exist, it is created and associated with the given
    # purposes and parent purposes. If it exists, it is returned as-is.
    #
    # @param name [String] The name of the Plate::Creator.
    # @param options [Hash] Options hash containing purposes and parent_purposes arrays.
    # @return [Plate::Creator] The found or newly created Plate::Creator.
    def create_plate_creator_if_does_not_exist(name, options)
      Plate::Creator.find_or_create_by(name:) do |creator|
        creator.plate_creator_purposes = purposes(options)
        creator.parent_purpose_relationships = parent_purposes(options)
      end
    end

    # Parses the purposes from the options hash and finds the corresponding PlatePurpose records.
    #
    # @param options [Hash] Options hash expected to contain a 'purposes' array.
    # @return [Array<PlatePurpose>] Array of PlatePurpose records matching the names.
    # @raise [ActiveRecord::RecordNotFound] if any purpose name is not found.
    def purposes(options)
      options.fetch('purposes', [])
        .each_with_object([]) do |purpose_name, purposes|
          purposes << PlatePurpose.find_by!(name: purpose_name)
        end
    end

    # Parses the parent purposes from the options hash and finds the corresponding PlatePurpose records.
    #
    # @param options [Hash] Options hash expected to contain a 'parent_purposes' array.
    # @return [Array<PlatePurpose>] Array of PlatePurpose records matching the names.
    #         If a parent purpose name is not found, it is skipped (returns nil).
    def parent_purposes(options)
      options.fetch('parent_purposes', [])
        .each_with_object([]) do |purpose_name, purposes|
          purposes << PlatePurpose.find_by!(name: purpose_name)
        end
    end

    # Returns the 'valid_options' value from the options hash as a string.
    #
    # This method fetches the 'valid_options' key from the provided options hash.
    # If the key is not present, it returns an empty string. The result is always
    # converted to a string, ensuring a consistent return type.
    #
    # @param options [Hash] The options hash, expected to possibly contain a 'valid_options' key.
    # @return [String] The value of 'valid_options' as a string, or an empty string if not present.
    def valid_options(options)
      options.fetch('valid_options', '').to_s
    end
  end
end
