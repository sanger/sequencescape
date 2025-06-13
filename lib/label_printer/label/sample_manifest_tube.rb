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

      # Returns the appropriate barcode for the given tube based on the barcode type.
      #
      # @param tube [Tube] The tube object for which the barcode is being retrieved.
      #   It is expected to respond to `human_barcode` and `machine_barcode`.
      # @return [String] The human-readable barcode if the barcode type is '2D Barcode',
      #   otherwise the machine-readable barcode.
      def barcode(tube)
        if @barcode_type == Rails.application.config.tube_manifest_barcode_config[:barcode_type_labels]['2d']
          return tube.human_barcode
        end
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
