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

    end
  end
end
