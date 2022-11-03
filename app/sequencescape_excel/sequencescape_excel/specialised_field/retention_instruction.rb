# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # Sets Retention Instruction on the plate custom metadata
    class RetentionInstruction
      include Base
      include ValueRequired

      validate :check_retention_instruction_matches_existing, if: :value_present?

      def update(_attributes = {})
        return unless valid?

        # do nothing unless we can access the plate (assuming asset will be a well receptacle)
        asset_plate = asset.plate
        return if asset_plate.blank?

        # most likely as we process the sample rows for a plate that a previous row will have
        # already created the retention instructions field in the plate metadata
        if asset_plate.custom_metadatum_collection.present?
          check_and_update_existing_custom_metadatum_collection
        else
          create_custom_metadatum_collection
        end
      end

      def check_retention_instruction_matches_existing
        current_collection = asset.plate.custom_metadatum_collection

        # ok if no custom metadata stored yet
        return if current_collection.blank?

        current_metadata = current_collection.metadata.symbolize_keys

        # ok if we have other metadata with different keys
        return unless current_metadata.key?(:retention_instruction)

        # ok if the already stored metadata value matches (set by another well already)
        return if current_metadata[:retention_instruction] == value

        errors.add(:base, "the retention instruction value #{value} must match for all wells on the same plate.")
      end

      private

      def create_custom_metadatum_collection
        current_plate = asset.plate
        cm =
          CustomMetadatumCollection.new(
            user: sample_manifest.user,
            asset: current_plate,
            metadata: {
              retention_instruction: value
            }
          )
        current_plate.custom_metadatum_collection = cm
        cm.save!
      end

      def check_and_update_existing_custom_metadatum_collection
        current_collection = asset.plate.custom_metadatum_collection
        current_metadata = current_collection.metadata.symbolize_keys

        # if the custom metadata already contains a retention instructions key (set by a
        # previous sample row) then the validation has checked it matches so there is nothing
        # further to do here
        return if current_metadata.key?(:retention_instruction)

        # otherwise we need add the retention instructions metadata field to the existing collection
        current_collection.update!(metadata: current_metadata.merge({ retention_instruction: value }))
      end
    end
  end
end
