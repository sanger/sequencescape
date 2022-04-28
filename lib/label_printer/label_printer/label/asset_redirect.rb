# frozen_string_literal: true
module LabelPrinter
  module Label
    class AssetRedirect # rubocop:todo Style/Documentation
      attr_reader :printables

      def initialize(options)
        @printables = options[:printables]
        @printer_type_class = options[:printer_type_class]
      end

      def labels
        case assets.first
        when Plate
          @printer_type_class.double_label? ? AssetPlateDouble.new(assets).labels : AssetPlate.new(assets).labels
        when Tube
          AssetTube.new(assets).labels
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
