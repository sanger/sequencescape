module LabelPrinter
  module Label

    class SequenomPlateRedirect

      attr_reader :plate_with_384_wells, :options

      def initialize(options)
        @plate_with_384_wells = options[:plate384]
        @options = options
      end

      def to_h
        if plate_with_384_wells
          return Sequenom384Plate.new(options).to_h
        else
          return Sequenom96Plate.new(options).to_h
        end
      end

    end

  end
end