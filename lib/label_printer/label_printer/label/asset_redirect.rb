module LabelPrinter
  module Label
    class AssetRedirect
      attr_reader :printables

      def initialize(options)
        @printables = options[:printables]
        @printer_type_class = options[:printer_type_class]
      end

      def to_h
        if assets.first.is_a? Plate
          if @printer_type_class.double_label?
            AssetPlateDouble.new(assets).to_h
          else
            AssetPlate.new(assets).to_h
          end
        elsif assets.first.is_a? Tube
          AssetTube.new(assets).to_h
        end
      end

      def assets
        printable_assets.each { |asset| asset.barcode! unless asset.barcode_number.present? }
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
