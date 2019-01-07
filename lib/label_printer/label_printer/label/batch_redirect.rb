module LabelPrinter
  module Label
    class BatchRedirect
      attr_reader :options

      def initialize(options)
        @printer_type_class = options[:printer_type_class]
        @options = options
      end

      def to_h
        if @printer_type_class.double_label?
          BatchPlateDouble.new(options).to_h
        else
          BatchPlate.new(options).to_h
        end
      end
    end
  end
end
