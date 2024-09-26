# frozen_string_literal: true
module LabelPrinter
  module Label
    class BasePlate
      include Label::MultipleLabels

      def build_label(plate)
        {
          top_left: top_left,
          bottom_left: bottom_left(plate),
          top_right: top_right(plate),
          bottom_right: bottom_right(plate),
          top_far_right: top_far_right(plate),
          barcode: barcode(plate),
          label_name: 'main_label'
        }
      end

      def top_left
        date_today
      end

      def bottom_left(plate)
        plate.human_barcode
      end

      def top_right(plate)
      end

      def bottom_right(plate)
      end

      def top_far_right(plate)
      end

      def barcode(plate)
        plate.machine_barcode
      end

      def date_today
        Date.today.strftime('%e-%^b-%Y')
      end

      def plates
        @plates || []
      end

      def assets
        plates
      end
    end
  end
end
