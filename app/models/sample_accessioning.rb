# frozen_string_literal: true

# technically should be called Sample::Accessioning, but keeping it next to sample for ease of maintenance
module SampleAccessioning
  extend ActiveSupport::Concern

  # Defines events related to sample accessioning which will be added to the Sample model
  # See EventfulRecord.has_many_events for details
  EVENTS = [
    [:assigned_accession_number!, Event::AccessioningEvent, :assigned_accession_number!],
    [:updated_accessioned_metadata!, Event::AccessioningEvent, :updated_accessioned_metadata!]
  ].freeze

  def self.tags
    @tags ||= []
  end

  extend IncludeTag

  include_tag(:sample_strain_att)
  include_tag(:sample_description)

  include_tag(:gender, mandatory_services: :EGA, downcase: true)
  include_tag(:phenotype, mandatory_services: :EGA)
  include_tag(:donor_id, mandatory_services: :EGA, as: 'subject_id')

  include_tag(:country_of_origin)
  include_tag(:date_of_sample_collection)

  # For attributing accessioning changes recorded in the SS events table
  attr_accessor :current_user # required to be set from the controller

  included do
    has_many :accession_sample_statuses, class_name: 'Accession::SampleStatus', dependent: :destroy

    # TODO: these validations are for accessioning and MIGHT belong in this model - see `on: :accession`
    # Together these two validations ensure that the first study exists and is valid for the ENA submission.
    validates_each(:ena_study, on: %i[accession ENA EGA]) do |record, _attr, value|
      record.errors.add(:base, 'Sample has no study') if value.blank?
    end
    validates_associated :ena_study, allow_blank: true, on: :accession, message: lambda { |record, _attr|
      "is invalid: #{record.ena_study.errors.full_messages.join(', ')}"
    }
    validates_associated :sample_metadata, on: %i[accession EGA ENA]

    # Processing_manifest is true if we're currently processing a manifest. We
    # disable accessioning, as we'll perform it explicitly later. This avoids
    # accidental calls to save triggering duplicate accessions.
    after_save :accession_and_handle_validation_errors, unless: -> { Sample::Current.processing_manifest }

    scope :without_accession,
          lambda {
            # Pick up samples where the accession number is either NULL or blank.
            # MySQL automatically trims '  ' so '  '=''
            joins(:sample_metadata).where(sample_metadata: { sample_ebi_accession_number: [nil, ''] })
          }
  end

  def ebi_accession_number
    sample_metadata.sample_ebi_accession_number
  end

  def accession_number?
    ebi_accession_number.present?
  end

  # Returns an array of studies linked to this sample that are eligible for accessioning
  # A study is eligible for accessioning if:
  # - it is active
  # - it is set to open or managed
  # - it is not set to never release
  # - it requires accessioning
  # - it has an accession number
  # @return [Array<Study>] the studies linked to this sample that are eligible for accessioning
  def studies_for_accessioning
    studies.select(&:samples_accessionable?)
  end

  # Criteria for whether a sample should be accessioned.
  # A sample should be accessioned if:
  # - it is part of a single accessionable study
  # - or all of the accessionable studies it is part of are open
  # @return [Boolean] true if the sample should be accessioned, false otherwise
  def should_be_accessioned?
    # If updating this method, also update should_be_accessioned_warning used in app/views/samples/_studies.html.erb

    case studies_for_accessioning.size
    when 0
      # No accessionable studies
      false
    when 1
      # Always accession
      true
    else
      # Samples belonging to more than one accessionables study can only be accessioned if all studies are open
      all_accessionable_studies_open?
    end
  end

  # NOTE: this does not check whether the current user is permitted to accession the sample,
  # nor if accessioning is enabled, as these belong in a controller or library, rather than the model.
  def accession_and_handle_validation_errors
    event_user = current_user # the event_user for this sample must be set from the calling controller
    Accession.accession_sample(self, event_user, perform_now: true)

  # Save error messages for later feedback to the user in a flash message
  rescue Accession::InternalValidationError
    # validation errors have already been added to the sample in Accession::Sample.validate!
  rescue Accession::Error, Faraday::Error => e
    message = Accession.user_error_message(e)
    errors.add(:base, message)
  end

  def ena_study
    studies.first
  end

  def study_for_accessioning
    # There should only be one study for accessioning, if we want to accession, so we return the only one
    studies_for_accessioning.first
  end

  # Validates that the sample and it's study are valid for ALL accessioning services accessioning
  def validate_sample_for_accessioning!
    accession_service = AccessionService.select_for_sample(self)
    (valid?(:accession) && valid?(accession_service.provider)) || raise(ActiveRecord::RecordInvalid, self)
  rescue ActiveRecord::RecordInvalid => e
    ena_study.errors.full_messages.each { |message| errors.add(:base, "#{message} on study") } unless ena_study.nil?
    raise e
  end

  def current_accession_status
    accession_sample_statuses.last
  end

  # Returns true if all accessionable studies are open, false otherwise.
  # @return [Boolean]
  def all_accessionable_studies_open?
    studies_for_accessioning.all? { |study| study.study_metadata.open? }
  end
end
