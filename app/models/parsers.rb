# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015,2016 Genome Research Ltd.

require 'csv'
require 'linefeed_fix'

module Parsers
  ENCODINGS = ['Windows-1252', 'iso-8859-1', 'utf-8', 'utf-16'].freeze
  PARSERS = [QuantParser, BioanalysisCsvParser, PlateReaderParser].freeze

  def self.parser_for(filename, content_type, content)
    return nil unless filename.downcase.end_with?('.csv') || content_type == 'text/csv'
    # While CSV tries to detect line endings, it isn't so great with some excel
    # exported CSVs, where a mix of \n and \r\n are used in the same document
    # This converts everything to \n before processing
    cleaned_content = LinefeedFix.scrub!(content.dup)
    csv = parse_with_fallback_encodings(cleaned_content)
    parser_class = PARSERS.detect { |parser| parser.parses?(csv) }
    parser_class ? parser_class.new(csv) : nil
  end

  def self.parse_with_fallback_encodings(content)
    encodings = ENCODINGS.dup
    begin
      CSV.parse(content)
    rescue ArgumentError => exception
      # Fetch the next fallback encoding
      encoding = encodings.shift
      # Re-raise the exception if we've run out
      raise exception if encoding.nil?
      # Force the new encoding
      content.force_encoding(encoding)
      # Try again
      retry unless encoding.nil?
    end
  end
end
