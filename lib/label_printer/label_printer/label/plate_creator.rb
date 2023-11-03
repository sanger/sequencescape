# frozen_string_literal: true
module LabelPrinter
  module Label
    class PlateCreator < BasePlate
      attr_reader :plates, :plate_purpose, :user_login

      def initialize(options)
        @plates = options[:plates]
        @plate_purpose = options[:plate_purpose]
        @user_login = options[:user_login]
      end

      def top_right(_plate)
        plate_purpose.name.to_s
      end

      def bottom_right(plate)
        "#{user_login} #{plate.studies.first&.abbreviation}"
      end

      def top_far_right(plate)
        plate.parent.try(:human_barcode).to_s
      end
    end
  end
end
