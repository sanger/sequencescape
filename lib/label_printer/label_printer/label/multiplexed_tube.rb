# frozen_string_literal: true
module LabelPrinter
  module Label
    class MultiplexedTube < BaseTube # rubocop:todo Style/Documentation
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

      # REMOVE AFTER DPL-364 IS DONE
      alias_method :top_line, :first_line
      alias_method :middle_line, :second_line
    end
  end
end
