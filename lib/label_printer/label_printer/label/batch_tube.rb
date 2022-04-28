# frozen_string_literal: true
module LabelPrinter
  module Label
    class BatchTube < BaseTube # rubocop:todo Style/Documentation
      attr_reader :count, :printable, :batch, :stock

      def initialize(options)
        @count = options[:count].to_i
        @printable = options[:printable]
        @batch = options[:batch]
        @stock = options[:stock]
      end

      def top_line(tube)
        stock.present? ? tube.name : tube.name_for_label
      end

      def tubes
        @tubes ||=
          if stock.present?
            # all info on a label including barcode is about target_asset stock asset
            requests.map { |request| request.target_labware.stock_asset }
          else
            # all info on a label including barcode is about target_asset
            requests.map(&:target_labware)
          end
      end

      private

      def requests
        request_ids = printable.select { |_barcode, check| check == 'on' }.keys
        requests = Request.find request_ids
      end

      def source_plate_barcode(tube)
        tube.name.split('-').first
      end

      def source_well_position(tube)
        tube.name.split('-').last
      end
    end
  end
end
