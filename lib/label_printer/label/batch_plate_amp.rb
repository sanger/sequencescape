# frozen_string_literal: true

require_relative 'batch_plates'

module LabelPrinter
  module Label
    # Label for printing plates specific to the AMP step in the Ultima sequencing pipeline
    # These particular plates don't exist as Labware in the system, we're just creating barcode labels for them,
    # based off the batch id and parent tube barcodes.
    class BatchPlateAmp
      include Label::MultipleLabels

      attr_reader :count

      def initialize(options)
        super()
        @count = options[:count].to_i
        @printable = options[:printable]
        @batch = options[:batch]
      end

      def build_label(parent_tube_barcode)
        {
          top_left: date_today,
          bottom_left: plate_barcode(parent_tube_barcode),
          top_right: nil,
          bottom_right: nil,
          top_far_right: nil,
          barcode: plate_barcode(parent_tube_barcode),
          label_name: 'main_label'
        }
      end

      def date_today
        Time.zone.today.strftime('%e-%^b-%Y')
      end

      def plate_barcode(tube_barcode)
        "#{@batch.id}_#{tube_barcode}"
      end

      def parent_tube_barcodes
        # comes from checkboxes selected on the page
        @printable.select { |_barcode, check| check == 'on' }.keys
      end

      # Not really assets, just identifiers for off-LIMS plates,
      # but method name kept for compatibility with MultipleLabels module
      def assets
        parent_tube_barcodes
      end
    end
  end
end
