# frozen_string_literal: true
module RecordLoader
  # == Schema Information
  #
  # Table name: plate_creators
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

    # Finds or creates a Plate::Creator by name.
    #
    # If a Plate::Creator with the given name exists, logs a warning and returns it.
    # Otherwise, creates a new Plate::Creator with the provided options.
    #
    # @param name [String] The name of the Plate::Creator.
    # @param options [Hash] Options hash containing purposes, parent_purposes, and valid_options.
    # @return [Plate::Creator] The found or newly created Plate::Creator.
    def create_plate_creator_if_does_not_exist(name, options)
      creator = Plate::Creator.find_by(name:)
      if creator
        Rails.logger.warn("Plate::Creator with name '#{name}' already exists. No changes made.")
        return creator
      end

      create_plate_creator!(name, options)
    end

    # Creates a new Plate::Creator and assigns purposes and parent purposes.
    #
    # Sets valid_options, associates purposes and parent purposes, saves the record,
    # and logs creation. Raises if creation fails.
    #
    # @param name [String] The name of the Plate::Creator.
    # @param options [Hash] Options hash containing purposes, parent_purposes, and valid_options.
    # @return [Plate::Creator] The newly created Plate::Creator.
    def create_plate_creator!(name, options)
      Plate::Creator.create!(name:).tap do |new_creator|
        new_creator.valid_options = valid_options(options)
        new_creator.plate_creator_purposes = purposes(options, new_creator)
        new_creator.parent_purpose_relationships = parent_purposes(options, new_creator)
        new_creator.save!
        Rails.logger.info("Plate::Creator with name '#{name}' created.")
      end
    end

    # Parses the purposes from the options hash and creates corresponding Plate::Creator::PurposeRelationship objects.
    #
    # @param options [Hash] Options hash expected to contain a 'purposes' array.
    # @return [Array<Plate::Creator::PurposeRelationship>] Array of Plate::Creator::PurposeRelationship objects.
    # @raise [ActiveRecord::RecordNotFound] if any purpose name is not found.
    def purposes(options, plate_creator)
      options.fetch('purposes', [])
        .each_with_object([]) do |purpose_name, purpose_relationships|
        PlatePurpose.find_by!(name: purpose_name).tap do |plate_purpose|
          purpose_relationships << Plate::Creator::PurposeRelationship.create!(
            plate_creator_id: plate_creator.id,
            plate_purpose_id: plate_purpose.id
          )
        end
      end
    end

    # Parses the parent purposes from the options hash and finds the corresponding PlatePurpose records.
    #
    # @param options [Hash] Options hash expected to contain a 'parent_purposes' array.
    # @return [Array<Plate::Creator::ParentPurposeRelationship>] Array of Plate::Creator::ParentPurposeRelationship objects.
    #         If a parent purpose name is not found, it is skipped (returns nil).
    def parent_purposes(options, plate_creator)
      options.fetch('parent_purposes', [])
        .each_with_object([]) do |purpose_name, parent_purpose_relationships|
        PlatePurpose.find_by!(name: purpose_name).tap do |plate_purpose|
          parent_purpose_relationships << Plate::Creator::ParentPurposeRelationship.create!(
            plate_creator_id: plate_creator.id,
            plate_purpose_id: plate_purpose.id
          )
        end
      end
    end

    # Returns the 'valid_options' value from the options hash as a string.
    #
    # This method fetches the 'valid_options' key from the provided options hash.
    # If the key is not present, it returns an empty string. The result is always
    # converted to a string, ensuring a consistent return type.
    #
    # @param options [Hash] The options hash, expected to possibly contain a 'valid_options' key.
    # @return [Hash] The value of 'valid_options' as a hash, or an empty hash if not present.
    def valid_options(options)
      options.fetch('valid_options', {}).to_h
    end
  end
end
