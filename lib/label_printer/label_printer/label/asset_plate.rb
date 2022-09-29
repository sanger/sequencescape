# frozen_string_literal: true
module LabelPrinter
  module Label
    class AssetPlate < BasePlate # rubocop:todo Style/Documentation
      attr_reader :plates

      def initialize(plates)
        @plates = plates
      end

      def top_right(plate)
        plate.plate_purpose.name.to_s
      end

      def bottom_right(plate)
        plate.studies.first&.abbreviation
      end

      def top_far_right(plate)
        plate.parent.try(:human_barcode).to_s
      end
    end
  end
end
