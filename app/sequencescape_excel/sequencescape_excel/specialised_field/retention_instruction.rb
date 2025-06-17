# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # Sets Retention Instruction on the labware custom metadata
    class RetentionInstruction
      include Base
      include ValueRequired
      include RetentionInstructionHelper

      def update(_attributes = {})
        return unless valid?

        # do nothing unless we can access the labware (assuming asset will be a well or tube receptacle)
        return if asset_labware.blank?

        update_retention_instructions
      end

      def asset_labware
        @asset_labware ||= asset.labware
      end

      def labware_metadatum_collection
        @labware_metadatum_collection ||= asset_labware.custom_metadatum_collection
      end

      def labware_metadata
        @labware_metadata ||= labware_metadatum_collection.metadata.symbolize_keys
      end

      private

      # Update the retention instruction on the labware
      def update_retention_instructions
        retention_enum_key = find_retention_instruction_key_for_value(value)
        return if retention_enum_key.blank?

        asset_labware.retention_instruction = retention_enum_key
        asset_labware.save!
      end
    end
  end
end
