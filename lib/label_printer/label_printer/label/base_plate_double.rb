# frozen_string_literal: true

module LabelPrinter
  module Label
    class BasePlateDouble
      include Label::MultipleDoubleLabels

      def barcode(plate)
        plate.ean13_barcode
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
