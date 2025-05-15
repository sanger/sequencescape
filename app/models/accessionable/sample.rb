# frozen_string_literal: true
# Handles the submission of {Sample} information to the ENA or EGA
# It should have a 1 to 1 mapping with Sequencescape {Sample samples}.
module Accessionable
  class Sample < Base
    ARRAY_EXPRESS_FIELDS = %w[
      genotype
      phenotype
      strain_or_line
      developmental_stage
      sex
      cell_type
      disease_state
      compound
      dose
      immunoprecipitate
      growth_condition
      rnai
      organism_part
      species
      time_point
      age
      treatment
    ].freeze

    attr_reader :common_name, :taxon_id, :links, :tags

    # rubocop:todo Metrics/MethodLength, Metrics/AbcSize
    def initialize(sample) # rubocop:todo Metrics/CyclomaticComplexity
      @sample = sample
      super(sample.ebi_accession_number)

      sampname = sample.sample_metadata.sample_public_name
      @name = sampname.presence || sample.name
      @name = @name.gsub(/[^a-z\d]/i, '_') if @name.present?

      @common_name = sample.sample_metadata.sample_common_name
      @taxon_id = sample.sample_metadata.sample_taxon_id

      # Tags from the 'ENA attributes' property group
      # NOTE[xxx]: This used to also look for 'ENA links' and push them to the 'data[:links]' value, but group was empty
      @links = []
      @tags =
        sample.tags.map { |datum| Tag.new(label_scope, datum.name, sample.sample_metadata[datum.tag], datum.downcase) }

      # TODO: maybe unify this with the previous loop
      # Don't send managed AE data to SRA
      unless sample.accession_service.private?
        ARRAY_EXPRESS_FIELDS.each do |datum|
          value = sample.sample_metadata.send(datum)
          next if value.blank?

          @tags << ArrayExpressTag.new(label_scope, datum, value)
        end
      end

      sample_hold = sample.sample_metadata.sample_sra_hold
      @hold = sample_hold.presence || 'hold'
    end

    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

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
      { alias: self.alias, accession: accession_number }.tap { |obj| obj.delete(:alias) if accession_number.present? }
    end

    # rubocop:todo Metrics/MethodLength
    def xml # rubocop:todo Metrics/AbcSize
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.SAMPLE_SET('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance') do
        xml.SAMPLE(sample_element_attributes) do
          xml.TITLE title unless title.nil?
          xml.SAMPLE_NAME do
            xml.COMMON_NAME common_name
            xml.TAXON_ID taxon_id
          end
          xml.SAMPLE_ATTRIBUTES { tags.each { |tag| xml.SAMPLE_ATTRIBUTE { tag.build(xml) } } } if tags.present?

          xml.SAMPLE_LINKS {} if links.present?
        end
      end
      xml.target!
    end

    # rubocop:enable Metrics/MethodLength

    def update_accession_number!(user, accession_number)
      @accession_number = accession_number
      add_updated_event(user, "Sample #{@sample.id}", @sample) if @accession_number
      @sample.sample_metadata.sample_ebi_accession_number = accession_number
      @sample.save!
    end

    def protect?(service)
      service.sample_visibility(@sample) == AccessionService::PROTECT
    end

    delegate :released?, to: :@sample
  end

  private

  class ArrayExpressTag < Base::Tag
    def label
      default_tag = "ArrayExpress-#{I18n.t("#{@scope}.#{@name}.label").tr(' ', '_').camelize}"
      I18n.t("#{@scope}.#{@name}.ena_label", default: default_tag)
    end
  end

  class EgaTag < Base::Tag
    def label
      default_tag = "EGA-#{I18n.t("#{@scope}.#{@name}.label").tr(' ', '_').camelize}"
      I18n.t("#{@scope}.#{@name}.ena_label", default: default_tag)
    end
  end
end
