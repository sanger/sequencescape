module Accession
  module Accessionable

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
  end
end