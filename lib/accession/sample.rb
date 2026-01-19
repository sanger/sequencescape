# frozen_string_literal: true
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

    validate :check_studies
    validate :check_required_fields, if: proc { |s| s.service.valid? }

    attr_reader :standard_tags, :sample, :studies, :service, :tags

    delegate :ebi_accession_number, to: :sample

    def initialize(standard_tags, sample)
      @standard_tags = standard_tags
      @sample = sample
      @studies = set_studies
      @tags = standard_tags.extract(sample.sample_metadata)
      @service = Service.new(exactly_one_study? ? studies.keys.first : nil)
    end

    def name
      @name ||= (sample.sample_metadata.sample_public_name || sample.name).sanitize
    end

    def title
      @title ||= sample.sample_metadata.sample_public_name || sample.sanger_sample_id
    end

    # Validates the sample for accessioning.
    #
    # If the sample is valid, the method returns silently.
    # If the sample is invalid, logs an error message and raisesAccession::InternalValidationError with
    # details of the validation errors.
    #
    # @raise [Accession::InternalValidationError] if the sample is not valid for accessioning
    def validate!
      return if valid?

      # Add errors from the accession sample to the underlying sample for user feedback
      @sample.errors.add(:base, errors.full_messages.join(', '))

      # Add sample context to the error message for logging
      error_message = "Sample '#{sample.name}' cannot be accessioned: #{errors.full_messages.join(', ')}"
      Rails.logger.error(error_message)
      raise Accession::InternalValidationError, error_message
    end

    def build_xml(xml) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      tag_groups = tags.by_group

      xml.SAMPLE_SET(XML_NAMESPACE) do # rubocop:disable Metrics/BlockLength
        xml.SAMPLE(alias: ebi_alias) do
          xml.TITLE title if title.present?
          xml.SAMPLE_NAME do
            tag_groups[:sample_name].each { |_k, tag| xml.tag!(tag.label.tr(' ', '_').upcase, tag.value) }
          end
          xml.SAMPLE_ATTRIBUTES do
            tag_groups[:sample_attributes].each do |_k, tag|
              xml.SAMPLE_ATTRIBUTE do
                xml.TAG tag.label
                if tag.label == 'gender'
                  xml.VALUE tag.value.downcase
                else
                  xml.VALUE tag.value
                end
              end
            end
            if service.ena?
              tag_groups[:array_express].each do |_k, tag|
                xml.SAMPLE_ATTRIBUTE do
                  xml.TAG tag.array_express_label
                  xml.VALUE tag.value
                end
              end
            end
          end
        end
      end
    end

    def ebi_alias
      sample.uuid
    end

    # Updates the accession number, saving the sample and adding an event to the events table
    # for viewing under sample history.
    def update_accession_number(accession_number, event_user)
      sample.sample_metadata.sample_ebi_accession_number = accession_number
      sample.sample_metadata.save # prevent an infinite loop due to after_save callbacks on sample.save
      sample.events.assigned_accession_number!('sample', accession_number, event_user)
    end

    def accessioned?
      ebi_accession_number.present?
    end

    private

    def set_studies
      sample.studies.for_sample_accessioning.group_by { |study| study.study_metadata.data_release_strategy }
    end

    def check_required_fields
      # Skip validation if the feature flag to skip accessioning tag validation is enabled.
      # EBI will still perform its own validation on submission.
      return if Flipper.enabled?(:y25_714_skip_accessioning_tag_validation)

      unless tags.meets_service_requirements?(service, standard_tags)
        errors.add(:sample, "does not have the required metadata: #{tags.missing.sort.to_sentence.dasherize}.")
      end
    end

    def check_studies
      exactly_one_study?
      study_requires_accessioning?
    end

    def exactly_one_study?
      # Check that sample is linked to exactly one study
      return true if studies.length == 1

      if studies.empty?
        errors.add(:sample, 'is not linked to any studies but must be linked to exactly one study.')
      else
        study_names = studies.values.flatten.map { |study| "'#{study.name}'" }.to_sentence
        errors.add(:sample, "must be linked to exactly one study but is linked to studies #{study_names}.")
      end
    end

    def study_requires_accessioning?
      # Check if study is present and allowed to be accessioned
      if sample.ena_study&.accession_required? != true # if true, accession; if false or nil, don't
        errors.add(:sample, 'is linked to a study that does not require accessioning.')
      end
    end
  end
end
