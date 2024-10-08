# frozen_string_literal: true
module LabelPrinter
  module Label
    class RobotBeds < BasePlate
      attr_reader :plates

      def initialize(beds)
        super()
        @plates = beds
      end

      def top_right(bed)
        "Bed #{bed.barcode}"
      end

      def bottom_right(bed)
        bed.ean13_barcode.to_s
      end
    end
  end
end
