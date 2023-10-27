# frozen_string_literal: true
module LabelPrinter
  module Label
    class MultiplexedTube < BaseTube
      attr_reader :tubes

      def initialize(options)
        @tubes = options[:assets]
        @count = options[:count]
      end

      def first_line(tube)
        tube.name_for_label.to_s
      end

      def second_line(tube)
        tube.human_barcode
      end
    end
  end
end
