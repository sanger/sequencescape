# frozen_string_literal: true
module LabelPrinter
  module Label
    class SampleManifestMultiplex < BaseTube # rubocop:todo Style/Documentation
      attr_reader :sample_manifest

      def initialize(options)
        @sample_manifest = options[:sample_manifest]
        @only_first_label = options[:only_first_label]
      end

      def first_line(_tube = nil)
        sample_manifest.study.abbreviation
      end

      def tubes
        [sample_manifest.printables]
      end

      # REMOVE AFTER DPL-364 IS DONE
      alias_method :top_line, :first_line
    end
  end
end
