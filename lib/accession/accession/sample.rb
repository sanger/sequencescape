module Accession
  class Sample
    # Validate the sample to ensure that it can be accessioned
    # The sample must:
    # - not be accessioned
    # - have at least one associated open or managed study that has been accessioned
    # - must not have an open and managed study that have been accessioned
    # - must have the required fields filled in based on the associated study
    # - if the sample has an open study then sample_taxon_id and sample_common_name must be completed
    # - if the sample has a managed study then gender, phenotype, donor_id must be completed
    # If the sample meets all of the above requirements it can be accessioned
    # If the sample has an open study it will be sent to the ENA
    # If the sample has a managed study it will be sent to the EGA

    include ActiveModel::Model
    include Accession::Accessionable

    validate :check_sample, :check_studies
    validate :check_required_fields, if: proc { |s| s.service.valid? }

    attr_reader :standard_tags, :sample, :studies, :service, :tags

    delegate :ebi_accession_number, to: :sample

    def initialize(standard_tags, sample)
      @standard_tags = standard_tags
      @sample = sample
      @studies = set_studies
      @tags = standard_tags.extract(sample.sample_metadata)
      @service = Service.new(studies_valid? ? studies.keys.first : nil)
    end

    def name
      @name ||= (sample.sample_metadata.sample_public_name  || sample.name).sanitize
    end

    def title
      @title ||= (sample.sample_metadata.sample_public_name || sample.sanger_sample_id)
    end

    def to_xml
      tag_groups = tags.by_group
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.SAMPLE_SET(XML_NAMESPACE) {
        xml.SAMPLE(alias: ebi_alias) {
          xml.TITLE title if title.present?
          xml.SAMPLE_NAME {
            tag_groups[:sample_name].each do |_k, tag|
              xml.tag!(tag.label, tag.value)
            end
          }
          xml.SAMPLE_ATTRIBUTES {
            tag_groups[:sample_attributes].each do |_k, tag|
              xml.SAMPLE_ATTRIBUTE {
                xml.TAG tag.label
                xml.VALUE tag.value
              }
            end
            if service.ena?
              tag_groups[:array_express].each do |_k, tag|
                xml.SAMPLE_ATTRIBUTE {
                  xml.TAG tag.array_express_label
                  xml.VALUE tag.value
                }
              end
            end
          }
        }
      }
      xml.target!
    end

    def ebi_alias
      sample.uuid
    end

    def update_accession_number(accession_number)
      sample.sample_metadata.sample_ebi_accession_number = accession_number
      sample.save
    end

    def accessioned?
      ebi_accession_number.present?
    end

  private

    def set_studies
      sample.studies
            .for_sample_accessioning
            .group_by { |study| study.study_metadata.data_release_strategy }
    end

    def check_sample
      if sample.sample_metadata.sample_ebi_accession_number.present?
        errors.add(:sample, 'has already been accessioned.')
      end
    end

    def check_required_fields
      unless tags.meets_service_requirements?(service, standard_tags)
        errors.add(:sample, "does not have the required metadata: #{tags.missing}.")
      end
    end

    def check_studies
      unless studies_valid?
        errors.add(:sample, 'has no appropriate studies.')
      end
    end

    def studies_valid?
      studies.length == 1
    end
  end
end
