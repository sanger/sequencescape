# frozen_string_literal: true
module LabelPrinter
  module Label
    class PlateToTubes < BaseTube # rubocop:todo Style/Documentation
      attr_reader :tubes

      def initialize(options)
        @tubes = options[:sample_tubes]
      end

      def first_line(tube)
        tube.name_for_label
      end

      # REMOVE AFTER DPL-364 IS DONE
      alias top_line first_line
    end
  end
end
