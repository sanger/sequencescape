# frozen_string_literal: true

require 'rexml/text'

#
# A {Sample} is an abstract concept, with represents the life of a sample of DNA/RNA
# as it moves through our processes. As a result, a sample may exist in multiple
# {Receptacle receptacles} at the same time, in the form of an {Aliquot}. As a result
# {Sample} is mainly concerned with dealing with aspects which are *always* true,
# such as tracking where it originally came from.
#
# An individual sample may be subject to library creation and sequencing multiple
# different times. These processes may be different each time.
#
# ## Sample Creation
# Samples can enter Sequencescape via a number of different routes. Such as:
# - {SampleManifest}: Large spreadsheets of sample information are generated.
#                     When uploaded samples are created in the corresponding
#                     {Receptacle}.
# - Heron: Heron samples get registered via the Api::V2::Heron::PlatesController
# - Special samples: Samples such as {PhiX} are generated internally
class Sample < ApplicationRecord # rubocop:todo Metrics/ClassLength
  # See https://api.rubyonrails.org/classes/ActiveSupport/CurrentAttributes.html
  class Current < ActiveSupport::CurrentAttributes
    attribute :processing_manifest
  end

  GC_CONTENTS = ['Neutral', 'High AT', 'High GC'].freeze
  GENDERS = ['Male', 'Female', 'Mixed', 'Hermaphrodite', 'Unknown', 'Not Applicable'].freeze
  DNA_SOURCES = [
    'Genomic',
    'Whole Genome Amplified',
    'Blood',
    'Cell Line',
    'Saliva',
    'Brain',
    'FFPE',
    'Amniocentesis Uncultured',
    'Amniocentesis Cultured',
    'CVS Uncultured',
    'CVS Cultured',
    'Fetal Blood',
    'Tissue'
  ].freeze
  SRA_HOLD_VALUES = %w[Hold Public Protect].freeze
  AGE_REGEXP =
    # rubocop:todo Layout/LineLength
    '\d+(?:\.\d+|\-\d+|\.\d+\-\d+\.\d+|\.\d+\-\d+\.\d+)?\s+(?:second|minute|day|week|month|year)s?|Not Applicable|N/A|To be provided'

  # rubocop:enable Layout/LineLength
  DOSE_REGEXP = '\d+(?:\.\d+)?\s+\w+(?:\/\w+)?|Not Applicable|N/A|To be provided'

  # The spreadsheets that people upload contain various fields that could be mistyped.  Here we ensure that the
  # capitalisation of these is correct.
  REMAPPED_ATTRIBUTES =
    {
      gc_content: GC_CONTENTS,
      gender: GENDERS,
      dna_source: DNA_SOURCES,
      sample_sra_hold: SRA_HOLD_VALUES
    }.transform_values { |v| v.index_by { |b| b.downcase } }

  self.per_page = 500

  include ModelExtensions::Sample
  include Api::SampleIo::Extensions
  include Uuid::Uuidable
  include StandardNamedScopes
  include SharedBehaviour::Named
  include Aliquot::Aliquotable
  include Commentable
  include Role::Authorized

  extend EventfulRecord
  extend ValidationStateGuard

  # @!attribute empty_supplier_sample_name
  #   @deprecated Only set on older samples where samples were created at manifest generation, rather than upload
  #   @return [Boolean] Returns true if the customer didn't fill in the supplier_sample_name. Indicating that
  #                     there is actually no sample in the well.

  # A spiral twists,
  # turns,
  # tracked,
  # we tell its story,
  # it tells our own

  extend Metadata
  has_metadata do
    include ReferenceGenome::Associations
    association(:reference_genome, :name, required: true)

    custom_attribute(:organism)
    custom_attribute(:cohort)
    custom_attribute(:country_of_origin)
    custom_attribute(:geographical_region)
    custom_attribute(:ethnicity)
    custom_attribute(:volume)
    custom_attribute(:mother)
    custom_attribute(:father)
    custom_attribute(:replicate)
    custom_attribute(:gc_content, in: Sample::GC_CONTENTS)
    custom_attribute(:gender, in: Sample::GENDERS)
    custom_attribute(:donor_id)
    custom_attribute(:dna_source, in: Sample::DNA_SOURCES)
    custom_attribute(:sample_public_name)
    custom_attribute(:sample_common_name)
    custom_attribute(:sample_strain_att)
    custom_attribute(:sample_taxon_id)
    custom_attribute(:sample_ebi_accession_number)
    custom_attribute(:sample_description)
    custom_attribute(:sample_sra_hold, in: Sample::SRA_HOLD_VALUES)
    custom_attribute(:sibling)
    custom_attribute(:is_resubmitted) # TODO[xxx]: selection of yes/no?
    custom_attribute(:date_of_sample_collection) # TODO[xxx]: Date field?
    custom_attribute(:date_of_sample_extraction) # TODO[xxx]: Date field?
    custom_attribute(:sample_extraction_method)
    custom_attribute(:sample_purified) # TODO[xxx]: selection of yes/no?
    custom_attribute(:purification_method) # TODO[xxx]: tied to the field above?
    custom_attribute(:concentration)
    custom_attribute(:concentration_determined_by)
    custom_attribute(:sample_type)
    custom_attribute(:sample_storage_conditions)
    custom_attribute(:collected_by)

    # Array Express
    custom_attribute(:genotype)
    custom_attribute(:phenotype)

    # custom_attribute(:strain_or_line) strain
    # TODO: split age in two fields and use a composed_of
    custom_attribute(:age, with: Regexp.new("\\A#{Sample::AGE_REGEXP}\\z"))
    custom_attribute(:developmental_stage)

    # custom_attribute(:sex) gender
    custom_attribute(:cell_type)
    custom_attribute(:disease_state)
    custom_attribute(:compound) # TODO : yes/no?
    custom_attribute(:dose, with: Regexp.new("\\A#{Sample::DOSE_REGEXP}\\z"))
    custom_attribute(:immunoprecipitate)
    custom_attribute(:growth_condition)
    custom_attribute(:rnai)
    custom_attribute(:organism_part)

    # custom_attribute(:species) common name
    custom_attribute(:time_point)

    # EGA
    custom_attribute(:treatment)
    custom_attribute(:subject)
    custom_attribute(:disease)

    custom_attribute(:genome_size)

    # Consent withdrawn
    custom_attribute(:consent_withdrawn)
    custom_attribute(:date_of_consent_withdrawn)
    custom_attribute(:user_id_of_consent_withdrawn)

    # These fields are warehoused, so need to match the encoding restrictions there
    # This excludes supplementary characters, which include emoji and rare kanji
    # @note phenotype isn't currently broadcast but has a field waiting in the warehouse
    validates :organism,
              :cohort,
              :country_of_origin,
              :geographical_region,
              :ethnicity,
              :mother,
              :father,
              :replicate,
              :donor_id,
              :sample_public_name,
              :sample_common_name,
              :sample_strain_att,
              :sample_description,
              :developmental_stage,
              :phenotype,
              utf8mb3: true

    # These fields are restricted further as they aren't expected to ever contain anything more than ASCII
    validates :sample_ebi_accession_number,
              format: {
                with: /\A[[:ascii:]]+\z/,
                message: 'only allows ASCII',
                allow_blank: true
              }

    with_options(on: %i[EGA ENA]) do
      validates :sample_taxon_id, presence: { message: 'is required' }
      validates :sample_common_name, presence: { message: 'is required' }
    end

    with_options(on: :EGA) do
      validates :gender, presence: { message: 'is required' }
      validates :phenotype, presence: { message: 'is required' }
      validates :donor_id, presence: { message: 'is required' }
    end

    after_initialize { |record| record.consent_withdrawn = false if record.consent_withdrawn.nil? }

    before_validation do |record|
      record.reference_genome_id = 1 if record.reference_genome_id.blank?

      # Unfortunately it appears that some of the functionality of this implementation relies on non-capitalisation!
      # So we remap the lowercased versions to their proper values here
      REMAPPED_ATTRIBUTES.each do |attribute, mapping|
        record[attribute] = mapping.fetch(record[attribute].try(:downcase), record[attribute])
        record[attribute] = nil if record[attribute].blank? # Empty strings should be nil
      end
    end
  end

  validates_associated :sample_metadata, on: %i[accession EGA ENA]

  include_tag(:sample_strain_att)
  include_tag(:sample_description)

  include_tag(:gender, services: :EGA, downcase: true)
  include_tag(:phenotype, services: :EGA)
  include_tag(:donor_id, services: :EGA, as: 'subject_id')

  include_tag(:country_of_origin)
  include_tag(:date_of_sample_collection)

  # Reopens the Sample::Metadata class which was defined by has_metadata above
  # Sample::Metadata tracks sample information, either for use in the lab, or passing to
  # the EBI
  class Metadata
    # This constraint doesn't match that described in the manifest, and is more permissive
    # It was added on conversion of out database to utf8 to address concerns that this would
    # lead to an increase in characters that their pipeline cannot process. Only a handful
    # of current samples violate this constraint.
    # We need to:
    # 1) Understand what the actual constraints are for supplier_name
    # 2) Apply appropriate constraints
    # 3) Ensure the help text in sample manifest matches
    # Note, *_changed? is rails magic, and not a string literal as rubocop might suggest
    validates :supplier_name,
              format: {
                with: /\A[[:ascii:]]+\z/,
                message: 'only allows ASCII'
              },
              if: :supplier_name_changed? && :supplier_name? # rubocop:disable Lint/LiteralAsCondition

    # here we are aliasing ArrayExpress attribute from normal one
    # This is easier that way so the name is exactly the name of the array-express field
    # and the values can be easily remapped
    # The other solution would be to have a different label for the accession file and the xml/edit page
    def strain_or_line
      sample_strain_att
    end

    def sex
      gender&.downcase
    end

    def species
      sample_common_name
    end

    belongs_to :user_of_consent_withdrawn,
               class_name: 'User',
               foreign_key: 'user_id_of_consent_withdrawn',
               inverse_of: :consent_withdrawn_sample_metadata

    # This is misleading, as samples are rarely released through
    # Sequencescape, so our flag gets out of sync with the ENA/EGA
    def released?
      sample_sra_hold == 'Public'
    end

    # Rarely actually used
    def release
      self.sample_sra_hold = 'Public'
      save!
    end
  end

  # Create relationships with samples that contain this Sample via SampleCompoundComponent.
  has_many(
    :joins_as_component_sample,
    foreign_key: :component_sample_id,
    inverse_of: :component_sample,
    class_name: 'SampleCompoundComponent'
  )
  has_many :compound_samples, through: :joins_as_component_sample, dependent: :destroy

  # Create relationships with samples that are contained by this Sample via SampleCompoundComponent.
  # Samples that are contained by this Sample should not themselves contain more Samples.
  # This is validated in the SampleCompoundComponent model.
  has_many(
    :joins_as_compound_sample,
    foreign_key: :compound_sample_id,
    inverse_of: :compound_sample,
    class_name: 'SampleCompoundComponent'
  )
  has_many :component_samples, through: :joins_as_compound_sample, dependent: :destroy

  has_many :assets, -> { distinct }, through: :aliquots, source: :receptacle
  deprecate assets: 'use receptacles instead, or labware if needed',
            deprecator: Rails.application.deprecators[:sequencescape]

  has_many :receptacles, -> { distinct }, through: :aliquots
  has_many :wells, -> { distinct }, through: :aliquots, source: :receptacle, class_name: 'Well'

  has_many_events do
    event_constructor(:created_using_sample_manifest!, Event::SampleManifestEvent, :created_sample!)
    event_constructor(:updated_using_sample_manifest!, Event::SampleManifestEvent, :updated_sample!)
  end

  has_many :study_samples, dependent: :destroy, inverse_of: :sample
  has_many :studies, through: :study_samples, inverse_of: :samples

  has_many :roles, as: :authorizable, dependent: :destroy, inverse_of: :authorizable
  has_many :owners, -> { where(roles: { name: 'owner' }) }, through: :roles, source: :users

  has_many :asset_groups, through: :receptacles

  has_many :requests, through: :assets
  has_many :submissions, through: :requests

  belongs_to :sample_manifest, inverse_of: :samples

  # This is a natural join to sample_manifest_asset based on a shared sanger_sample_id.
  # In the event that the sample is deleted, we want to leave the sample_manifest_asset unchanged,
  # so don't want to set a dependent option.
  has_one :sample_manifest_asset, foreign_key: :sanger_sample_id, primary_key: :sanger_sample_id, inverse_of: :sample

  has_many_lab_events
  broadcast_with_warren

  validates :name, presence: true
  validates :name,
            format: {
              with: /\A[\w_-]+\z/i,
              message: I18n.t('samples.name_format'),
              if: :new_name_format,
              on: :create
            }
  validates :name,
            format: {
              with: /\A[()+\s\w._-]+\z/i,
              message: I18n.t('samples.name_format'),
              if: :new_name_format,
              on: :update
            }
  validates :name,
            uniqueness: {
              on: :create,
              message: 'already in use',
              unless: :sample_manifest_id?,
              case_sensitive: false
            }

  validate :name_unchanged, if: :will_save_change_to_name?, on: :update

  validates :control_type,
            absence: {
              with: true,
              unless: :control?,
              message: 'should be blank if "control" is set to false'
            }

  enum :control_type, { negative: 0, positive: 1, 'pcr negative': 2, 'pcr positive': 3, 'lysate negative': 4 }

  enum :priority, { no_priority: 0, backlog: 1, surveillance: 2, priority: 3 }

  # this method has to be before validation_guarded_by
  def rename_to!(new_name)
    update!(name: new_name)
  end

  validation_guard(:can_rename_sample)
  validation_guarded_by(:rename_to!, :can_rename_sample)

  # Together these two validations ensure that the first study exists and is valid for the ENA submission.
  validates_each(:ena_study, on: %i[accession ENA EGA]) do |record, _attr, value|
    record.errors.add(:base, 'Sample has no study') if value.blank?
  end
  validates_associated(:ena_study, allow_blank: true, on: :accession)

  before_destroy :safe_to_destroy

  # Processing_manifest is true if we're currently processing a manifest. We
  # disable accessioning, as we'll perform it explicitly later. This avoids
  # accidental calls to save triggering duplicate accessions.
  after_save :accession_and_handle_validation_errors, unless: -> { Sample::Current.processing_manifest }

  # NOTE: Samples don't tend to get released through Sequencescape
  # so in reality these methods are usually misleading.
  delegate :released?, :release, to: :sample_metadata

  scope :with_gender, ->(*_names) { joins(:sample_metadata).where.not(sample_metadata: { gender: nil }) }

  scope :for_search_query,
        lambda { |query|
          # NOTE: This search is performed in two stages so that we can make best use of our indicies
          # A naive search forces a full table lookup for all queries, ignoring the index in the sample metadata table
          # instead favouring the sample_id index. Rather than trying to bend MySQL to our will, we'll solve the
          # problem rails side, and perform two queries instead. Even passing a scope into the query, thus allowing
          # rails to build subquery, results in a sub-optimal execution plan.

          md =
            Sample::Metadata.where(
              'supplier_name LIKE :left OR sample_ebi_accession_number = :exact',
              left: "#{query}%",
              exact: query
            ).pluck(:sample_id)

          # The query id is kept distinct from the metadata retrieved ids, as including a string in what is otherwise an
          # array of numbers seems to massively increase the query length.
          where(
            'name LIKE :wild OR id IN (:sm_ids) OR id = :qid',
            wild: "%#{query}%",
            sm_ids: md,
            query: query,
            qid: query.to_i
          )
        }

  scope :for_plate_and_order,
        lambda { |plate_id, order_id|
          joins(
            [
              'INNER JOIN aliquots ON aliquots.sample_id = samples.id',
              'INNER JOIN receptacles AS rc ON rc.id = aliquots.receptacle_id',
              'INNER JOIN well_links ON target_well_id = aliquots.receptacle_id AND well_links.type = "stock"',
              'INNER JOIN requests ON requests.asset_id = well_links.source_well_id'
            ]
          ).where(['rc.labware_id = ? AND requests.order_id = ?', plate_id, order_id])
        }

  scope :for_plate_and_order_as_target,
        lambda { |plate_id, order_id|
          joins(
            [
              'INNER JOIN aliquots ON aliquots.sample_id = samples.id',
              'INNER JOIN receptacles AS rc ON rc.id = aliquots.receptacle_id',
              'INNER JOIN requests ON requests.target_asset_id = aliquots.receptacle_id'
            ]
          ).where(['rc.labware_id = ? AND requests.order_id = ?', plate_id, order_id])
        }

  scope :without_accession,
        lambda {
          # Pick up samples where the accession number is either NULL or blank.
          # MySQL automatically trims '  ' so '  '=''
          joins(:sample_metadata).where(sample_metadata: { sample_ebi_accession_number: [nil, ''] })
        }

  # Truncates the sanger_sample_id for display on labels
  # - Returns the sanger_sample_id AS IS if it is nil or less than 10 characters
  # - Tries to truncate it to the last 7 digits, and returns that
  # - If it cannot extract 7 digits, the full sanger_sample_id is returned
  # @note This appears to be set up to handle legacy data. All currently generated
  #       Sanger sample ids will be meet criteria 1 or 2.
  # Earlier implementations were supposed to fall back to the name in the absence
  # of a sanger_sample_id, but the feature was incorrectly implemented, and would
  # have thrown an exception.
  def shorten_sanger_sample_id
    case sanger_sample_id
    when nil
      sanger_sample_id
    when sanger_sample_id.size < 10
      sanger_sample_id
    when /(\d{7})$/
      Regexp.last_match(1)
    else
      sanger_sample_id
    end
  end

  def ebi_accession_number
    sample_metadata.sample_ebi_accession_number
  end

  def accession_number?
    ebi_accession_number.present?
  end

  def error
    'Default error message'
  end

  def sample_empty?(supplier_sample_name = name)
    return true if empty_supplier_sample_name

    sample_supplier_name_empty?(supplier_sample_name)
  end

  def sample_supplier_name_empty?(supplier_sample_name)
    supplier_sample_name.blank? ||
      ['empty', 'blank', 'water', 'no supplier name available', 'none'].include?(supplier_sample_name.downcase)
  end

  # Return the highest priority accession service
  def accession_service
    services = studies.group_by { |s| s.accession_service.priority }
    return UnsuitableAccessionService.new([]) if services.empty?

    highest_priority = services.keys.max
    suitable_study = services[highest_priority].detect(&:send_samples_to_service?)
    return suitable_study.accession_service if suitable_study

    UnsuitableAccessionService.new(services[highest_priority])
  end

  def accession
    return unless configatron.accession_samples

    # TODO: {Y25-280} Uncomment this as part of improving error handling. If it proves problematic, it can be removed.
    # unless configatron.accession_samples
    #   raise AccessionService::AccessioningDisabledError, 'Accessioning is not enabled in this environment.'
    # end

    accessionable = build_accessionable
    validate_accessionable!(accessionable)
    enqueue_accessioning_job!(accessionable)
  end

  def accession_and_handle_validation_errors
    accession
    Rails.logger.info("Accessioning passed for sample '#{name}'")
  rescue AccessionService::AccessionServiceError => e
    # Save error messages for later feedback to the user in a flash message
    errors.add(:base, e.message)
  end

  def handle_update_event(user)
    events.updated_using_sample_manifest!(user)
  end

  def ena_study
    studies.first
  end

  def validate_ena_required_fields!
    (valid?(:accession) && valid?(accession_service.provider)) || raise(ActiveRecord::RecordInvalid, self)
  rescue ActiveRecord::RecordInvalid => e
    ena_study.errors.full_messages.each { |message| errors.add(:base, "#{message} on study") } unless ena_study.nil?
    raise e
  end

  def sample_reference_genome
    return sample_metadata.reference_genome if sample_metadata.reference_genome.try(:name).present?
    return study_reference_genome if study_reference_genome.try(:name).present?

    nil
  end

  def subject_type
    'sample'
  end

  # Consent withdraw attributes from sample metadata
  delegate :consent_withdrawn, :consent_withdrawn?, :consent_withdrawn=, to: :sample_metadata
  delegate :date_of_consent_withdrawn, :date_of_consent_withdrawn=, to: :sample_metadata
  delegate :user_id_of_consent_withdrawn, :user_id_of_consent_withdrawn=, to: :sample_metadata

  def friendly_name
    sanger_sample_id || name
  end

  def name_unchanged
    errors.add(:name, 'cannot be changed') unless can_rename_sample
    can_rename_sample
  end

  # sample can either be registered through sample manifest,
  # historically through studies/:id/sample_registration
  # or via external services like Heron
  def registered_through_manifest?
    sample_manifest.present?
  end

  # if sample is registered through sample manifest it should have supplier sample name
  # (without it the row is considered empty)
  # if sample was registered directly, only sample name is a required field, so supplier sample name can be empty
  # but it is reasonably safe to assume that required metadata was provided
  def can_be_included_in_submission?
    registered_through_manifest? ? sample_metadata.supplier_name.present? : true
  end

  def control_formatted
    return nil if control.nil?

    return 'No' if control == false

    type_text = control_type || 'type unspecified'
    "Yes (#{type_text})"
  end

  private

  def safe_to_destroy
    errors.add(:base, 'samples cannot be destroyed.')
    throw(:abort)
  end

  def build_accessionable
    Accession::Sample.new(Accession.configuration.tags, self)
  end

  def validate_accessionable!(accessionable)
    return if accessionable.valid?

    error_message = "Accessionable is invalid for sample '#{name}': #{accessionable.errors.full_messages.join(', ')}"
    Rails.logger.error(error_message)
    # TODO: {Y25-280} Uncomment this as part of improving error handling
    # raise AccessionService::AccessionValidationFailed, error_message
  end

  def enqueue_accessioning_job!(accessionable)
    job = Delayed::Job.enqueue(SampleAccessioningJob.new(accessionable), priority: 200)
    log_job_status(job)
  rescue StandardError => e
    # TODO: {Y25-280} Uncomment this as part of improving error handling
    # ExceptionNotifier.notify_exception(e, data: { message: 'Failed to enqueue accessioning job' })
    Rails.logger.error("Failed to enqueue accessioning job: #{e.message}")
    # TODO: {Y25-280} Uncomment this as part of improving error handling
    # raise
  end

  def log_job_status(job)
    if job
      Rails.logger.info("Accessioning job enqueued successfully: #{job.inspect}")
    else
      Rails.logger.warn('Accessioning job enqueue returned nil.')
    end
  end
end
