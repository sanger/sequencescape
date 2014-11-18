module Parsers

  def self.parser_for(filename, content)
    return nil unless filename.ends_with?('.csv')
    csv = FasterCSV.parse(content)
    return Parsers::BioanalysisCsvParser.new(csv) if Parsers::BioanalysisCsvParser.is_bioanalyzer?(filename, csv)
    nil
  end

end
