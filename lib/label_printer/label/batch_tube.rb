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

      # Returns the tubes (source_labware) of the selected requests of a batch.
      # For comparison, target_labware of a request is a Lane::Labware.
      #
      # @return [Labware] an array of Labware objects representing the tubes.
      def tubes
        @tubes ||=
          if stock.present?
            # all info on a label including barcode is about source_asset stock asset
            requests.map { |request| request.source_labware.stock_asset }
          else
            # all info on a label including barcode is about source_asset
            requests.map(&:source_labware)
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
