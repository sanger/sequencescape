# frozen_string_literal: true
module LabelPrinter
  module Label
    class AssetTube < BaseTube # rubocop:todo Style/Documentation
      attr_reader :tubes

      def initialize(tubes)
        @tubes = tubes
      end

      def first_line(tube)
        tube.name_for_label.to_s
      end

      # REMOVE AFTER DPL-364 IS DONE
      alias_method :top_line, :first_line
    end
  end
end
