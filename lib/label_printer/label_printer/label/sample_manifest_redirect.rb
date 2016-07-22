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
          return SampleManifestPlate.new(options).to_h
        when '1dtube'
          return SampleManifestTube.new(options).to_h
        when 'multiplexed_library'
          return SampleManifestMultiplex.new(options).to_h
        end
      end

    end

  end
end