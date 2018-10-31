module LabelPrinter
  module Label
    class AssetTube < BaseTube
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
