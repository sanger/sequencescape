# frozen_string_literal: true

require_relative 'base_plate_double'

module LabelPrinter
  module Label
    class SampleManifestPlateDouble < BasePlateDouble # rubocop:todo Style/Documentation
      attr_reader :sample_manifest, :only_first_label

      def initialize(options)
        @sample_manifest = options[:sample_manifest]
        @only_first_label = options[:only_first_label]
      end

      def create_label(plate)
        {
          left_text: plate.human_barcode,
          right_text: "#{sample_manifest.study.abbreviation} #{plate.barcode_number}",
          barcode: barcode(plate),
          label_name: 'main_label'
        }
      end

      def create_extra_label(_plate)
        { left_text: date_today, right_text: @sample_manifest.purpose.name, label_name: 'extra_label' }
      end

      def plates
        return [sample_manifest.printables.first] if only_first_label

        sample_manifest.printables
      end
    end
  end
end
