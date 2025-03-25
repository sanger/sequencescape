# frozen_string_literal: true
module LabelPrinter
  module Label
    class SampleManifestTube < BaseTube
      attr_reader :sample_manifest, :only_first_label

      def initialize(options)
        super()
        @sample_manifest = options[:sample_manifest]
        @only_first_label = options[:only_first_label]
      end

      # Builds a hash representing the label for a given tube.
      #
      # @param tube [Tube] The tube object for which the label is being built.
      #   It is expected to respond to `human_barcode`. This was overriden in this class
      #   for only to be applied for asset types `1dtube` and `library`.
      #
      # @return [Hash] A hash containing the label details:
      #   - :first_line [String] The first line of the label, derived from the tube.
      #   - :second_line [String] The second line of the label, derived from the tube.
      #   - :third_line [String] The third line of the label, derived from the tube.
      #   - :round_label_top_line [String] The top line of the round label, derived from the tube.
      #   - :round_label_bottom_line [String] The bottom line of the round label, derived from the tube.
      #   - :barcode [String] The human-readable barcode of the tube.
      #   - :label_name [String] The name of the label, set to 'main_label'.
      def build_label(tube)
        {
          first_line: first_line(tube),
          second_line: second_line(tube),
          third_line: third_line(tube),
          round_label_top_line: round_label_top_line(tube),
          round_label_bottom_line: round_label_bottom_line(tube),
          barcode: tube.human_barcode,
          label_name: 'main_label'
        }
      end

      def first_line(_tube = nil)
        sample_manifest.study.abbreviation
      end

      def tubes
        return [sample_manifest.printables.first] if only_first_label

        sample_manifest.printables
      end
    end
  end
end
