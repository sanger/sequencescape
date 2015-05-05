module Parsers

  def self.parser_for(filename, content_type, content)
    return nil unless filename.ends_with?('.csv') || content_type == 'text/csv'
    csv = FasterCSV.parse(content)
    return Parsers::BioanalysisCsvParser.new(csv) if Parsers::BioanalysisCsvParser.is_bioanalyzer?(csv)
    return Parsers::ISCXTenParser.new(csv) if Parsers::ISCXTenParser.is_isc_xten_file?(csv)
    nil
  end

end
