# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # Sets Retention Instruction on the labware custom metadata
    class RetentionInstruction
      include Base
      include ValueRequired
      include RetentionKeyHelper

      def update(_attributes = {})
        return unless valid?

        # do nothing unless we can access the labware (assuming asset will be a well or tube receptacle)
        return if asset_labware.blank?

        # NB. it is most likely that as we process the sample rows for a plate labware, that a previous row
        # will have already created the retention instructions field in the labware metadata
        if labware_metadatum_collection.present?
          check_and_update_existing_custom_metadatum_collection
        else
          update_labware
          asset_labware.custom_metadatum_collection = create_custom_metadatum_collection
        end
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

      def update_labware
        retention_enum_key = find_retention_instruction_key_for_value(value)
        return if retention_enum_key.blank?
        asset_labware.retention_instruction = retention_enum_key
        asset_labware.save!
      end

      def create_custom_metadatum_collection
        cmc =
          CustomMetadatumCollection.new(
            user: sample_manifest.user,
            asset: asset_labware,
            metadata: {
              retention_instruction: value
            }
          )
        cmc.save!
        cmc
      end

      def check_and_update_existing_custom_metadatum_collection
        if labware_metadata.key?(:retention_instruction)
          # update the existing value
          labware_metadatum_collection.update(metadata: { 'retention_instruction' => value })
        else
          # otherwise we need add the retention instructions metadata field to the existing collection
          labware_metadatum_collection.update!(metadata: labware_metadata.merge({ retention_instruction: value }))
        end
      end
    end
  end
end
