module LabelPrinter
  module Label
    class SampleManifestTube < BaseTube
      attr_reader :sample_manifest, :only_first_label

      def initialize(options)
        @sample_manifest = options[:sample_manifest]
        @only_first_label = options[:only_first_label]
      end

      def top_line(_tube = nil)
        sample_manifest.study.abbreviation
      end

      def tubes
        return [sample_manifest.printables.first] if only_first_label
        sample_manifest.printables
      end
    end
  end
end
