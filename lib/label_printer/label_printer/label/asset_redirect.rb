module LabelPrinter
  module Label
    class AssetRedirect
      attr_reader :printables

      def initialize(options)
        @printables = options[:printables]
        @printer_type_class = options[:printer_type_class]
      end

      def to_h
        case assets.first
        when Plate
          if @printer_type_class.double_label?
            AssetPlateDouble.new(assets).to_h
          else
            AssetPlate.new(assets).to_h
          end
        when Tube
          AssetTube.new(assets).to_h
        end
      end

      def assets
        printable_assets.each { |asset| asset.barcode! if asset.barcode_number.blank? }
      end

      private

      def printable_assets
        if printables.is_a? Labware
          [printables]
        else
          ids = printables.select { |_id, check| check == 'true' }.keys
          Labware.find(ids)
        end
      end
    end
  end
end
