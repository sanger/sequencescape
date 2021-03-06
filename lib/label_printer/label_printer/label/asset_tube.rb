module LabelPrinter
  module Label
    class AssetTube < BaseTube # rubocop:todo Style/Documentation
      attr_reader :tubes

      def initialize(tubes)
        @tubes = tubes
      end

      def top_line(tube)
        tube.name_for_label.to_s
      end
    end
  end
end
