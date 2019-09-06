module LabelPrinter
  module Label
    class BatchTube < BaseTube
      attr_reader :count, :printable, :batch, :stock

      def initialize(options)
        @count = options[:count].to_i
        @printable = options[:printable]
        @batch = options[:batch]
        @stock = options[:stock]
      end

      def top_line(tube)
        if stock.present?
          tube.name
        elsif batch.multiplexed?
          tag_range = tube.receptacle.tag_range
          tag_range.nil? ? tube.name : "(#{tag_range}) #{tube.id}"
        elsif tube.is_a? PacBioLibraryTube
          source_plate_barcode(tube)
        else
          tube.name_for_label
        end
      end

      def middle_line(tube)
        tube.is_a?(PacBioLibraryTube) ? source_well_position(tube) : super
      end

      def round_label_top_line(tube)
        tube.is_a?(PacBioLibraryTube) ? source_well_position(tube) : super
      end

      def round_label_bottom_line(tube)
        tube.is_a?(PacBioLibraryTube) ? source_plate_barcode(tube).split(//).last(4).join : super
      end

      def tubes
        @tubes ||=  if stock.present?
                      if batch.multiplexed?
                        # all info on a label including barcode is about target_asset first child
                        requests.map { |request| request.target_labware.children.first }
                      else
                        # all info on a label including barcode is about target_asset stock asset
                        requests.map { |request| request.target_labware.stock_asset }
                      end
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
