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

      def labels # rubocop:todo Metrics/MethodLength
        case sample_manifest.asset_type
        when 'plate', 'library_plate'
          if @printer_type_class.double_label?
            SampleManifestPlateDouble.new(options).labels
          else
            SampleManifestPlate.new(options).labels
          end
        when '1dtube', 'library'
          SampleManifestTube.new(options).labels
        when 'multiplexed_library'
          SampleManifestMultiplex.new(options).labels
        end
      end
    end
  end
end
