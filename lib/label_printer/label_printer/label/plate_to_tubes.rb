module LabelPrinter
  module Label

    class PlateToTubes < BaseTube

      attr_reader :tubes

      def initialize(options)
        @tubes = options[:sample_tubes]
      end

      def top_line(tube)
        tube.tube_name
      end

    end
  end
end
