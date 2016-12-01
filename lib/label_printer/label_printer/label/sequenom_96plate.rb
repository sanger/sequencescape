module LabelPrinter
  module Label
    class Sequenom96Plate < BasePlate
      attr_reader :plates, :count

      def initialize(options)
        @plates = options[:plates]
        @count = options[:count].to_i
      end

      def top_right(plate)
        "#{plate.label_text_top}"
      end

      def bottom_right(plate)
        "#{plate.label_text_bottom}"
      end

      def top_far_right(plate)
        "#{plate.plate_purpose.name}"
      end
    end
  end
end
