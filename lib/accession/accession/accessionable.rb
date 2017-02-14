module Accession
  # Standard methods used by things that can be accesioned e.g sample
  module Accessionable
    # An accessionable file needs an original filename which relates to the remote filename.
    class AccessionableFile < Tempfile
      attr_accessor :original_filename
    end

    attr_reader :ebi_alias

    def schema_type
      @schema_type ||= self.class.to_s.demodulize.downcase
    end

    def date
      @date ||= Time.now.utc.iso8601
    end

    def filename
      @filename ||= "#{ebi_alias_datestamped}.#{schema_type}.xml"
    end

    def ebi_alias_datestamped
      "#{ebi_alias}-#{date}"
    end

    def to_xml
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.target!
    end

    def to_file
      AccessionableFile.open("#{schema_type}_file").tap do |f|
        f.write(to_xml << "\n")
        f.original_filename = filename
      end
    end
  end
end
