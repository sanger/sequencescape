
module LabelPrinter
  module Label
    class BatchTube < BaseTube
      attr_reader :count, :printable, :batch, :stock

      def initialize(options)
        @count = options[:count].to_i
        @printable = options[:printable]
        @batch = options[:batch]
        @batch = options[:batch]
        @stock = options[:stock]
      end

      def top_line(tube)
        if stock.present?
          tube.name
        elsif batch.multiplexed?
          tag_range = tube.tag_range
          tag_range.nil? ? tube.name : "(#{tag_range}) #{tube.id}"
        else
          tube.tube_name
        end
      end

      def tubes
        @tubes ||=  if stock.present?
                      if batch.multiplexed?
                        # all info on a label including barcode is about target_asset first child
                        requests.map { |request| request.target_asset.children.first }
                      else
                        # all info on a label including barcode is about target_asset stock asset
                        requests.map { |request| request.target_asset.stock_asset }
                      end
                    else
                      # all info on a label including barcode is about target_asset
                      requests.map { |request| request.target_asset }
                    end
      end

      private

      def requests
        request_ids = printable.select { |_barcode, check| check == 'on' }.keys
        requests = Request.find request_ids
      end
    end
  end
end
