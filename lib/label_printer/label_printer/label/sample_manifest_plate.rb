module LabelPrinter
  module Label
    class SampleManifestPlate < BasePlate
      attr_reader :sample_manifest, :only_first_label

      def initialize(options)
        @sample_manifest = options[:sample_manifest]
        @only_first_label = options[:only_first_label]
      end

      def top_right(_plate = nil)
        PlatePurpose.stock_plate_purpose.name.to_s
      end

      def bottom_right(plate)
        "#{sample_manifest.study.abbreviation} #{plate.barcode}"
      end

      def plates
        return [sample_manifest.printables.first] if only_first_label
        sample_manifest.printables
      end
    end
  end
end
