module Accessionable
  class Sample < Base
    attr_reader :common_name, :taxon_id, :links, :tags
    def initialize(sample)
      @sample = sample
      super(sample.ebi_accession_number)

      sampname = sample.sample_metadata.sample_public_name
      @name = sampname.blank? ? sample.name : sampname
      @name = @name.gsub(/[^a-z\d]/i,'_') unless @name.blank?

      #@__filename = "#{ submission_id }-#{ sample.id }.sample.xml"
      #@__alias    = "#{ submission_id }-#{ sample.id }"

      @common_name = sample.sample_metadata.sample_common_name
      @taxon_id           = sample.sample_metadata.sample_taxon_id

      # Tags from the 'ENA attributes' property group
      # NOTE[xxx]: This used to also look for 'ENA links' and push them to the 'data[:links]' value, but group was empty
      @links = []
      @tags  = [ :sample_strain_att, :sample_description ].map do |datum|
        Tag.new(label_scope, datum, sample.sample_metadata[datum])
      end

      #TODO maybe unify this with the previous loop
      # Don't send managed AE data to SRA
      if !sample.accession_service.private?
        ::Sample::ArrayExpressFields.each do |datum|
          value = sample.sample_metadata.send(datum)
          next unless value.present?
          @tags << ArrayExpressTag.new(label_scope, datum, value)
        end
      end

      sample_hold = sample.sample_metadata.sample_sra_hold
      @hold = sample_hold.blank? ? 'hold' : sample_hold
    end

    def object_id
     @sample.id
    end

    def xml
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.SAMPLE_SET('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance') {
      xml.SAMPLE(:alias => self.alias, :accession => self.accession_number) {
        xml.SAMPLE_NAME {
          xml.COMMON_NAME  self.common_name
          xml.TAXON_ID     self.taxon_id
        }
        xml.SAMPLE_ATTRIBUTES {
          self.tags.each do |tag|
            xml.SAMPLE_ATTRIBUTE {
              tag.build(xml)
            }
          end
        } unless self.tags.blank?

        xml.SAMPLE_LINKS {

        } unless self.links.blank?
      }
    }
    return xml.target!
    end

    def update_accession_number!(user, accession_number)
      @accession_number = accession_number
      add_updated_event(user, "Sample #{@sample.id}",  @sample) if @accession_number
      @sample.sample_metadata.sample_ebi_accession_number = accession_number
      @sample.save!
    end

    def protect?(service)
      service.sample_visibility(@sample) == AccessionService::Protect
    end

    def released?
      @sample.released?
    end

  end
  private

  class ArrayExpressTag < Base::Tag
    def label
      default_tag =  "ArrayExpress-#{I18n.t("#{@scope}.#{ @name }.label").gsub(" ","_").camelize}"
      I18n.t("#{@scope}.#{ @name }.era_label", :default => default_tag)
    end
  end

  class EgaTag< Base::Tag
    def label
      default_tag =  "EGA-#{I18n.t("#{@scope}.#{ @name }.label").gsub(" ","_").camelize}"
      I18n.t("#{@scope}.#{ @name }.era_label", :default => default_tag)
    end
  end
end
