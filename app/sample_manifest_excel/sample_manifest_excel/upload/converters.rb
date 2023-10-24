# frozen_string_literal: true

module SampleManifestExcel
  module Upload
    module Converters
      BLANK_CHARS = '[ \u00A0]'
      BLANK_CHARS_REGEXP = /^(#{Converters::BLANK_CHARS}*)(.*?)(#{Converters::BLANK_CHARS}*)$/

      def strip_all_blanks(obj)
        obj.respond_to?(:match) ? obj.match(BLANK_CHARS_REGEXP)[2] : obj
      end
    end
  end
end
