# frozen_string_literal: true
module LabelPrinter
  module Label
    class BatchMultiplex < BaseTube # rubocop:todo Style/Documentation
      attr_reader :count, :printable, :batch

      def initialize(options)
        @count = options[:count].to_i
        @printable = options[:printable]
        @batch = options[:batch]
      end

      def top_line(tube)
        "(p) #{tube.name}"
      end

      def tubes
        if batch.multiplexed?
          ids = printable.select { |_id, check| check == 'on' }.keys
          Labware.find ids
        end
      end
    end
  end
end
