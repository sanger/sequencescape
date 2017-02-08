module LabelPrinter
  module Label
    class AssetRedirect
      attr_reader :printables

      def initialize(options)
        @printables = options[:printables]
      end

      def to_h
        if assets.first.is_a? Plate
          AssetPlate.new(assets).to_h
        elsif assets.first.is_a? Tube
          AssetTube.new(assets).to_h
        end
      end

      def assets
        _assets.each { |asset| asset.barcode! unless asset.barcode.present? }
      end

      def _assets
        if printables.is_a? Asset
          [printables]
        else
          ids = printables.select { |_id, check| check == 'true' }.keys
          Asset.find(ids)
        end
      end
    end
  end
end
