# frozen_string_literal: true
require 'csv'
require 'linefeed_fix'

module Parsers
  ENCODINGS = %w[Windows-1252 iso-8859-1 utf-8 utf-16].freeze
  PARSERS = [QuantParser, BioanalysisCsvParser, PlateReaderParser, PbmcCountParser].freeze

  def self.parser_for(filename, content_type, content)
    return nil unless filename.downcase.end_with?('.csv') || content_type == 'text/csv'

    # While CSV tries to detect line endings, it isn't so great with some excel
    # exported CSVs, where a mix of \n and \r\n are used in the same document
    # This converts everything to \n before processing
    cleaned_content = LinefeedFix.scrub!(content.dup)
    csv = parse_with_fallback_encodings(cleaned_content)
    parser_class =
      PARSERS.detect do |parser|
        parser.parses?(csv)
      rescue StandardError
        false
      end
    parser_class&.new(csv)
  end

  def self.parse_with_fallback_encodings(content)
    encodings = ENCODINGS.dup
    begin
      CSV.parse(content)
    rescue ArgumentError => e
      # Fetch the next fallback encoding
      encoding = encodings.shift

      # Re-raise the exception if we've run out
      raise e if encoding.nil?

      # Force the new encoding
      content.force_encoding(encoding)

      # Try again
      retry unless encoding.nil?
    end
  end
end
