# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # Sets Retention Instruction on the plate custom metadata
    class RetentionInstruction
      include Base
      include ValueRequired

      def update(_attributes = {})
        return unless valid?

        # do nothing unless we can access the plate (assuming asset will be a well receptacle)
        return if asset.plate.blank?

        # it is most likely that as we process the sample rows for a plate, that a previous row
        # will have already created the retention instructions field in the plate metadata
        if plate_metadatum_collection.present?
          check_and_update_existing_custom_metadatum_collection
        else
          asset.plate.custom_metadatum_collection = create_custom_metadatum_collection
        end
      end

      def plate_metadatum_collection
        @plate_metadatum_collection ||= asset.plate.custom_metadatum_collection
      end

      def current_plate_metadata
        @current_plate_metadata ||= plate_metadatum_collection.metadata.symbolize_keys
      end

      private

      def create_custom_metadatum_collection
        cmc =
          CustomMetadatumCollection.new(
            user: sample_manifest.user,
            asset: asset.plate,
            metadata: {
              retention_instruction: value
            }
          )
        cmc.save!
        cmc
      end

      def check_and_update_existing_custom_metadatum_collection
        if current_plate_metadata.key?(:retention_instruction)
          # update the existing value
          plate_metadatum_collection.update(metadata: { 'retention_instruction' => value })
        else
          # otherwise we need add the retention instructions metadata field to the existing collection
          plate_metadatum_collection.update!(metadata: current_plate_metadata.merge({ retention_instruction: value }))
        end
      end
    end
  end
end
