# frozen_string_literal: true

module SequencescapeExcel
  module NullObjects
    ##
    # NullProcessor
    class NullProcessor
      def initialize(_upload)
      end

      def run(tag_group)
      end

      def samples_updated?
        false
      end

      def processed?
        false
      end

      def valid?
        false
      end

      def sample_manifest_updated?
        false
      end

      def errors
        msg = 'does not exist. Double check that Sanger sample ids have not been changed.'
        msg += ' Check that the delayed jobs worker has run.' if Rails.env.development?
        { sample_manifest: msg }
      end
    end
  end
end
