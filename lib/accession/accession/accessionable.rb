module Accession
  module Accessionable
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
      @filename ||= "#{ebi_alias}-#{date}.#{schema_type}.xml"
    end

    def to_xml
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.target!
    end

    def to_file
      AccessionableFile.open("#{schema_type}_file").tap do |f|
        f.write(to_xml)
        f.original_filename = filename
      end
    end
  end
end
