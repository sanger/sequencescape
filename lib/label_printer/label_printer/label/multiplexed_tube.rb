module LabelPrinter
  module Label
    class MultiplexedTube < BaseTube
      attr_reader :tubes

      def initialize(options)
        @tubes = options[:assets]
        @count = options[:count]
      end

      def top_line(tube)
        tube.name_for_label.to_s
      end

      def middle_line(tube)
        tube.sanger_human_barcode
      end
    end
  end
end
