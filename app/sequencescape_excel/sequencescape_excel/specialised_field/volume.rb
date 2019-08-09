# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    # Volume
    class Volume
      include Base

      def update(_attributes = {})
        return unless valid?

        sample.sample_metadata.volume = value
        create_qc_record if value.present?
      end

      private

      def create_qc_record
        ActiveRecord::Base.transaction do
          qc_assay = QcAssay.find_or_create_by!(
            lot_number: "sample_manifest_id:#{sample_manifest_asset.sample_manifest.id}"
          )
          asset.qc_results.build(
            qc_assay: qc_assay,
            key: 'volume',
            value: value.to_f,
            assay_type: 'customer_supplied',
            units: 'ul',
            assay_version: 'v0.0'
          )
        end
      end
    end
  end
end
