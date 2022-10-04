# frozen_string_literal: true
module LabelPrinter
  module Label
    class BaseTube # rubocop:todo Style/Documentation
      include Label::MultipleLabels

      def build_label(tube)
        {
          first_line: first_line(tube),
          second_line: second_line(tube),
          third_line: third_line(tube),
          round_label_top_line: round_label_top_line(tube),
          round_label_bottom_line: round_label_bottom_line(tube),
          barcode: barcode(tube),
          label_name: 'main_label'
        }
      end

      def first_line(tube); end

      def second_line(tube)
        tube.barcode_number
      end

      def third_line(_tube)
        date_today
      end

      def round_label_top_line(tube)
        tube.prefix
      end

      def round_label_bottom_line(tube)
        tube.barcode_number
      end

      def barcode(tube)
        tube.machine_barcode
      end

      def tubes
        @tubes || []
      end

      def assets
        tubes
      end

      def date_today
        Date.today.strftime('%e-%^b-%Y')
      end
    end
  end
end
