# frozen_string_literal: true

module SampleManifestExcel
  module Upload
    module Converters
      BLANK_CHARS = '[ \u00A0]'

      def strip_all_blanks(obj)
        if obj.respond_to?(:match)
          obj.match(/^(#{Converters::BLANK_CHARS}*)(.*?)(#{Converters::BLANK_CHARS}*)$/)[2]
        else
          obj
        end
      end
    end
  end
end
