# frozen_string_literal: true
module LabelPrinter
  module Label
    class SampleManifestTube < BaseTube
      attr_reader :sample_manifest, :only_first_label

      # Initialised only for 1dtube and library
      def initialize(options)
        super()
        @sample_manifest = options[:sample_manifest]
        @only_first_label = options[:only_first_label]
        @barcode_type = options[:barcode_type]
      end

      def barcode(tube)
        return tube.human_barcode if @barcode_type == '2D Barcode'
        tube.machine_barcode
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
