# frozen_string_literal: true
module LabelPrinter
  module Label
    class BatchRedirect # rubocop:todo Style/Documentation
      attr_reader :options

      def initialize(options)
        @printer_type_class = options[:printer_type_class]
        @options = options
      end

      def labels
        @printer_type_class.double_label? ? BatchPlateDouble.new(options).labels : BatchPlate.new(options).labels
      end
    end
  end
end
