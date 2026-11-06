# frozen_string_literal: true

require_relative 'base_plate_double'

module LabelPrinter
  module Label
    class AssetPlateDouble < BasePlateDouble
      attr_reader :plates

      def initialize(plates)
        super()
        @plates = plates
      end

      def build_label(plate)
        {
          left_text: plate.human_barcode,
          right_text: right_text(plate),
          barcode: barcode(plate),
          label_name: 'main_label'
        }
      end

      # The barcode's prefix and number, or the whole barcode when it has no
      # number, such as an external one
      def right_text(plate)
        return plate.human_barcode if plate.barcode_number.blank?

        "#{plate.prefix} #{plate.barcode_number}"
      end

      def build_extra_label(plate)
        { left_text: date_today, right_text: plate.purpose.name, label_name: 'extra_label' }
      end
    end
  end
end
