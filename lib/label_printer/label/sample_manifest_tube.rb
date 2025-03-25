# frozen_string_literal: true
module LabelPrinter
  module Label
    class SampleManifestTube < BaseTube
      attr_reader :sample_manifest, :only_first_label

      def initialize(options)
        super()
        @sample_manifest = options[:sample_manifest]
        @only_first_label = options[:only_first_label]
        @barcode_type = options[:barcode_type]
      end

      def barcode(tube)
        barcode_type = @barcode_type
        if barcode_type.nil? || barcode_type == '1D Barcode'
          tube.machine_barcode
        else
          tube.human_barcode
        end
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
