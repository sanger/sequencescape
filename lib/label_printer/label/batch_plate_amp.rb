# frozen_string_literal: true

require_relative 'batch_plates'

module LabelPrinter
  module Label
    # Label for printing plates specific to the Amp step in the Ultima sequencing pipeline
    # These particular plates don't exist as Labware in the system, we're just creating barcode labels for them,
    # based off the batch id and parent tube barcodes.
    class BatchPlateAmp
      include Label::MultipleLabels

      def build_label(barcode)
        {
          top_left: date_today,
          bottom_left: barcode,
          top_right: nil,
          bottom_right: nil,
          top_far_right: nil,
          barcode: barcode,
          label_name: 'main_label'
        }
      end

      def date_today
        Time.zone.today.strftime('%e-%^b-%Y')
      end

      def plate_barcodes
        printable.select { |_barcode, check| check == 'on' }. # name or id from checkbox
      end

      # Not really assets, just identifiers for off-LIMS plates,
      # but method name kept for compatibility with MultipleLabels module
      def assets
        plate_barcodes
      end
    end
  end
end
