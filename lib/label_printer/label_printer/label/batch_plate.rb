module LabelPrinter
  module Label
    class BatchPlate < BasePlate
      attr_reader :count, :printable, :batch

      def initialize(options)
        @count = options[:count].to_i
        @printable = options[:printable]
        @batch = options[:batch]
      end

      def top_right(_plate = nil)
        batch.studies.first.abbreviation
      end

      def bottom_right(plate)
        "#{batch.output_plate_role} #{batch.output_plate_purpose.name} #{plate.barcode_number}"
      end

      def plates
        barcodes = printable.select { |_barcode, check| check == 'on' }.keys
        batch.plate_group_barcodes.keys.select { |plate| barcodes.include?(plate.human_barcode) }
      end
    end
  end
end
