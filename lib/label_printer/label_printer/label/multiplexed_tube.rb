module LabelPrinter
  module Label
    class MultiplexedTube < BaseTube
      attr_reader :tubes, :count

      def initialize(options)
        @tubes = options[:assets]
        @count = options[:count].to_i
      end

      def top_line(tube)
        tube.name_for_label.to_s
      end
    end
  end
end
