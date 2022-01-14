# frozen_string_literal: true

require_relative 'base_plate_double'

module LabelPrinter
  module Label
    class AssetPlateDouble < BasePlateDouble # rubocop:todo Style/Documentation
      attr_reader :plates

      def initialize(plates)
        @plates = plates
      end

      def build_label(plate)
        {
          left_text: plate.human_barcode,
          right_text: "#{plate.prefix} #{plate.barcode_number}",
          barcode: barcode(plate),
          label_name: 'main_label'
        }
      end

      def build_extra_label(plate)
        { left_text: date_today, right_text: plate.purpose.name, label_name: 'extra_label' }
      end
    end
  end
end
