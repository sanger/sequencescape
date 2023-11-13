# frozen_string_literal: true
module LabelPrinter
  module Label
    class Swipecard
      def initialize(attributes)
        @swipecard = attributes[:swipecard]
        @user_login = attributes[:user_login]
      end

      def build_label
        { top_left: @user_login, barcode: @swipecard, label_name: 'main_label' }
      end

      def labels
        [build_label]
      end
    end
  end
end
