# frozen_string_literal: true

require_relative 'base_plate_double'

module LabelPrinter
  module Label
    class AssetPlateDouble < BasePlateDouble # rubocop:todo Style/Documentation
      attr_reader :plates

      def initialize(plates)
        @plates = plates
      end

      def create_label(plate)
        {
          left_text: plate.human_barcode,
          right_text: "#{plate.prefix} #{plate.barcode_number}",
          barcode: barcode(plate)
        }
      end

      def create_extra_label(plate)
        { left_text: date_today, right_text: plate.purpose.name }
      end
    end
  end
end
