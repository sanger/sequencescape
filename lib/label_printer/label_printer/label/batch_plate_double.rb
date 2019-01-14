# frozen_string_literal: true

require_relative 'base_plate_double'
require_relative '../batch_plates'

module LabelPrinter
  module Label
    class BatchPlateDouble < BasePlateDouble
      include Label::BatchPlates
      attr_reader :count, :printable, :batch

      def initialize(options)
        @count = options[:count].to_i
        @printable = options[:printable]
        @batch = options[:batch]
      end

      def create_label(plate)
        { left_text: plate.human_barcode.to_s,
          right_text: plate.barcode_number.to_s,
          barcode: barcode(plate) }
      end

      def create_extra_label(plate)
        { left_text: date_today,
          right_text: "#{@batch.output_plate_role} #{@batch.output_plate_purpose.name} #{plate.barcode_number} #{@batch.studies.first.abbreviation}" }
      end
    end
  end
end
