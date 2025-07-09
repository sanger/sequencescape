# frozen_string_literal: true
module LabelPrinter
  module Label
    class BatchTube < BaseTube
      attr_reader :count, :printable, :batch, :stock

      def initialize(options)
        super()
        @count = options[:count].to_i
        @printable = options[:printable]
        @batch = options[:batch]
        @stock = options[:stock]
      end

      def first_line(tube)
        if stock.present?
          tube.name
        else
          tube.respond_to?(:name_for_label) ? tube.name_for_label : tube.name
        end
      end

      def tubes
        # If target_asset is a lane, use its parent tube.
        # If stock is present, all label info (including barcode) is about the stock asset;
        # otherwise, all label info is about the target_labware.
        @tubes ||= begin
          targets = requests.map { |r| r.target_asset.is_a?(Lane) ? r.target_labware.parent : r.target_labware }
          stock.present? ? targets.map(&:stock_asset) : targets
        end
      end

      private

      def requests
        request_ids = printable.select { |_barcode, check| check == 'on' }.keys
        Request.find request_ids
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
