# frozen_string_literal: true
module LabelPrinter
  module Label
    class Swipecard
      def initialize(attributes)
        @swipecard = attributes[:swipecard]
        @user_login = attributes[:user_login]
      end

      def build_label
        { left_text: @user_login, barcode: @swipecard, label_name: 'main' }
      end

      def labels
        [build_label]
      end
    end
  end
end
