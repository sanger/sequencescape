module LabelPrinter
  module Label
    class SampleManifestRedirect
      attr_reader :options, :sample_manifest

      def initialize(options)
        @sample_manifest = options[:sample_manifest]
        @options = options
      end

      def to_h
        case sample_manifest.asset_type
        when 'plate'
          SampleManifestPlate.new(options).to_h
        when '1dtube'
          SampleManifestTube.new(options).to_h
        when 'multiplexed_library'
          SampleManifestMultiplex.new(options).to_h
        end
      end
    end
  end
end
