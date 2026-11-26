# frozen_string_literal: true
module LabelPrinter
  module Label
    class SampleManifestRedirect
      attr_reader :options, :sample_manifest

      def initialize(options)
        @sample_manifest = options[:sample_manifest]
        @printer_type_class = options[:printer_type_class]
        @options = options
      end

      def labels
        case sample_manifest.asset_type
        when 'plate', 'library_plate'
          plate_labels
        when '1dtube', 'library', 'compound_tube'
          SampleManifestTube.new(options).labels
        when 'compound_plate'
          SampleManifestPlate.new(options).labels
        when 'multiplexed_library'
          SampleManifestMultiplex.new(options).labels
        end
      end

      private

      def plate_labels
        return SampleManifestPlateDouble.new(options).labels if @printer_type_class.double_label?

        SampleManifestPlate.new(options).labels
      end
    end
  end
end
