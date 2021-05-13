module LabelPrinter
  module Label
    class BatchRedirect # rubocop:todo Style/Documentation
      attr_reader :options

      def initialize(options)
        @printer_type_class = options[:printer_type_class]
        @options = options
      end

      def to_h
        @printer_type_class.double_label? ? BatchPlateDouble.new(options).to_h : BatchPlate.new(options).to_h
      end
    end
  end
end
