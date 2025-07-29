# frozen_string_literal: true

require_relative 'batch_plates'

module LabelPrinter
  module Label
    class BatchPlate < BasePlate
      include Label::BatchPlates

      attr_reader :count, :printable, :batch

      def initialize(options)
        super()
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
    end
  end
end
