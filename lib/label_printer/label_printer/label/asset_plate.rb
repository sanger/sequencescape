module LabelPrinter
  module Label
    class AssetPlate < BasePlate
      attr_reader :plates

      def initialize(plates)
        @plates = plates
      end

      def top_right(plate)
        "#{plate.prefix} #{plate.barcode_number}"
      end

      def bottom_right(plate)
        "#{plate.name_for_label} #{plate.barcode_number}"
      end
    end
  end
end
