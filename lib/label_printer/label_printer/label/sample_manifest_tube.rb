# frozen_string_literal: true
module LabelPrinter
  module Label
    class SampleManifestTube < BaseTube # rubocop:todo Style/Documentation
      attr_reader :sample_manifest, :only_first_label

      def initialize(options)
        @sample_manifest = options[:sample_manifest]
        @only_first_label = options[:only_first_label]
      end

      def first_line(_tube = nil)
        sample_manifest.study.abbreviation
      end

      # REMOVE AFTER DPL-364 IS DONE
      alias_method :top_line, :first_line

      def tubes
        return [sample_manifest.printables.first] if only_first_label

        sample_manifest.printables
      end
    end
  end
end
