# frozen_string_literal: true

module AssetRefactor
  # Labware reflects a physical piece of plastic which can move round the
  # lab.
  module Labware
    # Labware specific methods
    module Methods
      attr_reader :storage_location_service

      def labwhere_location
        @labwhere_location ||= lookup_labwhere_location
      end

      # Labware reflects the physical piece of plastic corresponding to an asset
      def labware
        self
      end

      def storage_location
        @storage_location ||= obtain_storage_location
      end

      private

      def obtain_storage_location
        if labwhere_location.present?
          @storage_location_service = 'LabWhere'
          labwhere_location
        else
          @storage_location_service = 'None'
          'LabWhere location not set. Could this be in ETS?'
        end
      end

      def lookup_labwhere_location
        lookup_labwhere(machine_barcode) || lookup_labwhere(human_barcode)
      end

      def lookup_labwhere(barcode)
        begin
          info_from_labwhere = LabWhereClient::Labware.find_by_barcode(barcode)
        rescue LabWhereClient::LabwhereException => e
          return "Not found (#{e.message})"
        end
        return info_from_labwhere.location.location_info if info_from_labwhere.present? && info_from_labwhere.location.present?
      end
    end
  end
end
