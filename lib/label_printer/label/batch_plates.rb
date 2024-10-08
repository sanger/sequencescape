# frozen_string_literal: true

module LabelPrinter
  module Label
    module BatchPlates
      def plates
        barcodes = printable.select { |_barcode, check| check == 'on' }.keys
        batch.plate_group_barcodes.keys.select { |plate| barcodes.include?(plate.human_barcode) }
      end
    end
  end
end
