module Accession
  module Accessionable
    
    def xml_alias
    end

    def schema_type
      @schema_type ||= self.class.to_s.demodulize.downcase
    end

    def date
      @date ||= Time.now.utc.iso8601
    end

    def filename
      @filename ||= "#{xml_alias}-#{date}.#{schema_type}.xml"
    end
  end
end