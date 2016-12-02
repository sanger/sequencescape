module LabelPrinter
  module Label
    class Robot < BasePlate
      attr_reader :plates

      def initialize(robot)
        @plates = robot
      end

      def top_right(robot)
        "Robot #{robot.name}"
      end

      def top_far_right(plate)
        ""
      end      

      def bottom_right(robot)
        "#{robot.ean13_barcode}"
      end
    end
  end
end
