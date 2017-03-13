# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015,2016 Genome Research Ltd.

module Accessionable
  class Sample < Base
    attr_reader :common_name, :taxon_id, :links, :tags
    def initialize(sample)
      @sample = sample
      super(sample.ebi_accession_number)

      sampname = sample.sample_metadata.sample_public_name
      @name = sampname.blank? ? sample.name : sampname
      @name = @name.gsub(/[^a-z\d]/i, '_') unless @name.blank?

      @common_name = sample.sample_metadata.sample_common_name
      @taxon_id    = sample.sample_metadata.sample_taxon_id

      # Tags from the 'ENA attributes' property group
      # NOTE[xxx]: This used to also look for 'ENA links' and push them to the 'data[:links]' value, but group was empty
      @links = []
      @tags  = sample.tags.map do |datum|
        Tag.new(label_scope, datum.name, sample.sample_metadata[datum.tag], datum.downcase)
      end

      # TODO: maybe unify this with the previous loop
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

    def accessionable_id
     @sample.id
    end

    def alias
      @sample.uuid
    end

    def title
      @sample.sample_metadata.sample_public_name || @sample.sanger_sample_id
    end

    def sample_element_attributes
      # In case the accession number is defined, we won't send the alias
      {
        alias: self.alias,
        accession: accession_number
      }.tap do |obj|
        obj.delete(:alias) unless accession_number.blank?
      end
    end

    def xml
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.SAMPLE_SET('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance') {
        xml.SAMPLE(sample_element_attributes) {
          xml.TITLE title unless title.nil?
          xml.SAMPLE_NAME {
            xml.COMMON_NAME  common_name
            xml.TAXON_ID     taxon_id
          }
          xml.SAMPLE_ATTRIBUTES {
            tags.each do |tag|
              xml.SAMPLE_ATTRIBUTE {
                tag.build(xml)
              }
            end
          } unless tags.blank?

          xml.SAMPLE_LINKS {} unless links.blank?
        }
      }
      xml.target!
    end

    def update_accession_number!(user, accession_number)
      @accession_number = accession_number
      add_updated_event(user, "Sample #{@sample.id}", @sample) if @accession_number
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
      default_tag = "ArrayExpress-#{I18n.t("#{@scope}.#{@name}.label").tr(" ", "_").camelize}"
      I18n.t("#{@scope}.#{@name}.ena_label", default: default_tag)
    end
  end

  class EgaTag < Base::Tag
    def label
      default_tag = "EGA-#{I18n.t("#{@scope}.#{@name}.label").tr(" ", "_").camelize}"
      I18n.t("#{@scope}.#{@name}.ena_label", default: default_tag)
    end
  end
end
