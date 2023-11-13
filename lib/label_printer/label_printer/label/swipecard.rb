# frozen_string_literal: true
module LabelPrinter
  module Label
    class Swipecard
      def initialize(attributes)
        @swipecard = attributes[:swipecard]
        @user_login = attributes[:user_login]
      end

      # Returns values for the fields of the label. They are used by the
      # the printmybarcode service to populate the label template.
      #
      # @return [Hash] a hash of label field values
      #
      def build_label
        { left_text: @user_login, barcode: @swipecard, label_name: 'main_label' }
      end

      def labels
        [build_label]
      end
    end
  end
end
