# frozen_string_literal: true
module Accession
  # Standard methods used by things that can be accesioned e.g sample
  module Accessionable
    attr_reader :ebi_alias

    def schema_type
      @schema_type ||= self.class.to_s.demodulize.downcase
    end

    def date
      @date ||= Time.now.utc.iso8601
    end

    def ebi_alias_datestamped
      "#{ebi_alias}-#{date}"
    end

    def filename
      @filename ||= clean_path("#{ebi_alias_datestamped}.#{schema_type}.xml")
    end

    def to_xml
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.target!
    end

    # Creates a Tempfile containing the XML representation of the accessionable.
    # Needs to be closed or unlinked after use.
    #
    # @return [Tempfile] A temporary file with the XML content.
    def to_file
      file = Tempfile.new(['', "_#{filename}"]) # preserve original filename as the filename suffix
      file.write("#{to_xml}\n")
      file.rewind
      file
    end

    private

    # Remove characters that are not safe for file paths
    def clean_path(str)
      str.gsub(/[^A-Za-z0-9.\-_]/, '')
    end
  end
end
