# frozen_string_literal: true
require 'aasm'

# A Study is a collection of various {Sample samples} and the work done on them.
# They are perhaps slightly overloaded, and provide:
# - A means of grouping together samples for administrative purposes
# - A means of generating EGAS/ERP study accession numbers at the ENA/EGA
#   - @see Accessionable::Study
#   - These accession numbers are used at data release to group samples together for publication
#   - For managed/EGA studies, also ties the data to an {Accessionable::Dac} and {Accessionable::Policy}
# - A means of generating the aforementioned {Accessionable::Dac} and {Accessionable::Policy}
#   @note These should DEFINITELY be separate entities
# - A means of tying data to internal data-release timings
# - A means to apply internal data access policies to released sequencing data
# - A means to tie interested parties to the samples and the work done on them
# - A way of specifying common ways of filtering/processing generated data. eg. filter human sequence
# - The service with which a {Sample} will be accessioned (eg. EGA/ENA)
#
# When a {Sample} enters Sequencescape it will usually be associated with a single {Study},
# usually determined by the {Study} associated with the {SampleManifest}. This study
# will be recorded on the {Aliquot} in the stock {Receptacle}, and additionally a
# {StudySample} will record this association.
#
# When work is requested an {Order} will be created, specifying a list of {Receptacle receptacles}
# and the {Study} for which this work is being performed. This will set
# {Request#initial_study_id initial study id on request} and in turn will be recorded on any
# downstream {Aliquot aliquots}. Critically, it is the study specified on the {Aliquot} in the {Lane}
# which will influence processes like data release and data access.
#
# @note This is really quite convoluted, and couples together administrative organization
#       alongside accessioning and data-access rules. It results in samples being tied to
#       an EGAS/ERP far too early in their lifecycle, and as a result we often need to perform
#       'sample moves'. Although we do need to know if samples are open(ENA) or managed(EGA) at the
#       point of accessioning.
class Study < ApplicationRecord # rubocop:todo Metrics/ClassLength
  # It has to be here, as there are has_many through: :roles associations in modules
  # Includes / Extendes
  has_many :roles

  # Includes / Extendes
  include StudyReport::StudyDetails
  include ModelExtensions::Study
  include Api::StudyIo::Extensions
  include Uuid::Uuidable
  include EventfulRecord
  include AASM
  include DataRelease
  include Commentable
  include SharedBehaviour::Named
  include ReferenceGenome::Associations
  include SampleManifest::Associations
  include Role::Authorized

  extend EventfulRecord
  extend Metadata
  extend Attributable::Association::Target

  # Constants
  STOCK_PLATE_PURPOSES = ['Stock Plate', 'Stock RNA Plate'].freeze
  YES = 'Yes'
  NO = 'No'
  YES_OR_NO = [YES, NO].freeze
  Other_type = 'Other'

  STUDY_SRA_HOLDS = %w[Hold Public].freeze

  DATA_RELEASE_STRATEGY_OPEN = 'open'
  DATA_RELEASE_STRATEGY_MANAGED = 'managed'
  DATA_RELEASE_STRATEGY_NOT_APPLICABLE = 'not applicable'
  DATA_RELEASE_STRATEGIES = [
    DATA_RELEASE_STRATEGY_OPEN,
    DATA_RELEASE_STRATEGY_MANAGED,
    DATA_RELEASE_STRATEGY_NOT_APPLICABLE
  ].freeze

  DATA_RELEASE_TIMING_STANDARD = 'standard'
  DATA_RELEASE_TIMING_NEVER = 'never'
  DATA_RELEASE_TIMING_DELAYED = 'delayed'
  DATA_RELEASE_TIMING_IMMEDIATE = 'immediate'
  DATA_RELEASE_TIMING_PUBLICATION = 'delay until publication'

  DATA_RELEASE_TIMINGS = [
    DATA_RELEASE_TIMING_STANDARD,
    DATA_RELEASE_TIMING_IMMEDIATE,
    DATA_RELEASE_TIMING_DELAYED
  ].freeze

  OLD_DATA_RELEASE_PREVENTION_REASONS = ['data validity', 'legal', 'replication of data subset'].freeze
  DATA_RELEASE_PREVENTION_REASON_OTHER = 'Other (please specify)'
  DATA_RELEASE_PREVENTION_REASONS = [
    'Pilot or validation studies - DAC approval not required',
    'Collaborators will share data in a research repository - DAC approval not required',
    'Prevent harm (e.g sensitive studies or biosecurity) - DAC approval required',
    'Protecting IP - DAC approval required',
    DATA_RELEASE_PREVENTION_REASON_OTHER
  ].freeze

  OLD_DATA_RELEASE_DELAY_FOR_OTHER = 'other'
  DATA_RELEASE_DELAY_FOR_OTHER = 'Other (please specify below)'
  OLD_DATA_RELEASE_DELAY_REASONS = ['other', 'phd study'].freeze
  DATA_RELEASE_DELAY_REASONS_STANDARD = [
    'PhD study',
    'Capacity building',
    'Intellectual property protection',
    'Additional time to make data FAIR',
    DATA_RELEASE_DELAY_FOR_OTHER
  ].freeze
  DATA_RELEASE_DELAY_REASONS_ASSAY = ['assay of no other use'].freeze

  DATA_RELEASE_DELAY_PERIODS = ['3 months', '6 months', '9 months', '12 months', '18 months'].freeze

  # Class variables
  self.per_page = 500

  attr_accessor :approval, :run_count, :total_price

  # Associations
  has_many_events
  has_many_lab_events

  role_relation(:followed_by, 'follower')
  role_relation(:managed_by, 'manager')
  role_relation(:collaborated_with, 'collaborator')

  belongs_to :user

  has_many :data_access_contacts, -> { where(roles: { name: 'Data Access Contact' }) }, through: :roles, source: :users
  has_many :followers, -> { where(roles: { name: 'follower' }) }, through: :roles, source: :users
  has_many :managers, -> { where(roles: { name: 'manager' }) }, through: :roles, source: :users
  has_many :owners, -> { where(roles: { name: 'owner' }) }, through: :roles, source: :users
  has_many :study_samples, inverse_of: :study
  has_many :orders
  has_many :submissions, through: :orders
  has_many :samples, through: :study_samples, inverse_of: :studies
  has_many :batches
  has_many :asset_groups
  has_many :study_reports
  has_many :aliquots
  has_many :initial_requests, class_name: 'Request', foreign_key: :initial_study_id
  has_many :assets_through_aliquots, -> { distinct }, through: :aliquots, source: :receptacle
  has_many :assets_through_requests, -> { distinct }, through: :initial_requests, source: :asset
  has_many :requests, through: :assets_through_aliquots, source: :requests_as_source
  has_many :request_types, -> { distinct }, through: :requests
  has_many :items, -> { distinct }, through: :requests
  has_many :projects, -> { distinct }, through: :orders
  has_many :comments, as: :commentable
  has_many :events, -> { order('created_at ASC, id ASC') }, as: :eventful
  has_many :documents, as: :documentable
  has_many :sample_manifests
  has_many :suppliers, -> { distinct }, through: :sample_manifests

  # Can have many key value pairs of metadata
  has_many :poly_metadata, as: :metadatable, dependent: :destroy

  # Validations
  validates :name, uniqueness: { case_sensitive: false }, presence: true, latin1: true
  validates :name, length: { maximum: 200 }
  validates :abbreviation,
            format: {
              with: /\A[\w_-]+\z/i,
              allow_blank: false,
              message: 'cannot contain spaces or be blank'
            }
  validate :validate_ethically_approved

  # Callbacks
  before_validation :set_default_ethical_approval
  after_touch :rebroadcast

  aasm column: :state, whiny_persistence: true do
    state :pending, initial: true
    state :active, enter: :mark_active
    state :inactive, enter: :mark_deactive

    event :reset do
      transitions to: :pending, from: %i[inactive active]
    end

    event :activate do
      transitions to: :active, from: %i[pending inactive]
    end

    event :deactivate do
      transitions to: :inactive, from: %i[pending active]
    end
  end

  broadcast_with_warren

  squishify :name

  has_metadata do
    include StudyType::Associations
    include DataReleaseStudyType::Associations
    include ReferenceGenome::Associations
    include FacultySponsor::Associations
    include Program::Associations

    association(:study_type, :name, required: true)
    association(:data_release_study_type, :name, required: true)
    association(:reference_genome, :name, required: true)
    association(:faculty_sponsor, :name, required: true)
    association(:program, :name, required: true)

    custom_attribute(:prelim_id, with: /\A[a-zA-Z]\d{4}\z/, required: false)
    custom_attribute(:study_description, required: true)
    custom_attribute(:contaminated_human_dna, required: true, in: YES_OR_NO)
    custom_attribute(:remove_x_and_autosomes, required: true, default: 'No', in: YES_OR_NO)
    custom_attribute(:separate_y_chromosome_data, required: true, default: false, boolean: true)
    custom_attribute(:study_project_id)
    custom_attribute(:study_abstract)
    custom_attribute(:study_study_title)
    custom_attribute(:study_ebi_accession_number)
    custom_attribute(:study_sra_hold, required: true, default: 'Hold', in: STUDY_SRA_HOLDS)
    custom_attribute(:contains_human_dna, required: true, in: YES_OR_NO)
    custom_attribute(:commercially_available, required: true, in: YES_OR_NO)
    custom_attribute(:study_name_abbreviation)

    custom_attribute(
      :data_release_strategy,
      required: true,
      in: DATA_RELEASE_STRATEGIES,
      default: DATA_RELEASE_STRATEGY_MANAGED
    )
    custom_attribute(:data_release_standard_agreement, default: YES, in: YES_OR_NO, if: :managed?)

    custom_attribute(
      :data_release_timing,
      required: true,
      default: DATA_RELEASE_TIMING_STANDARD,
      in: DATA_RELEASE_TIMINGS + [DATA_RELEASE_TIMING_NEVER]
    )
    custom_attribute(
      :data_release_delay_reason,
      required: true,
      in: [*DATA_RELEASE_DELAY_REASONS_STANDARD, *DATA_RELEASE_DELAY_REASONS_ASSAY, *OLD_DATA_RELEASE_DELAY_REASONS],
      if: :delayed_release?
    )

    with_options(if: :delay_until_publication?) do
      custom_attribute(
        :data_release_timing_publication_comment, required: true
      )
    end
    custom_attribute(:data_release_delay_period, required: true, in: DATA_RELEASE_DELAY_PERIODS, if: :delayed_release?)
    custom_attribute(:bam, default: true)

    with_options(if: :delayed_for_other_reasons?) do
      custom_attribute(:data_release_delay_other_comment, required: true)
      custom_attribute(:data_release_delay_reason_comment)
    end

    custom_attribute(:dac_policy, default: configatron.default_policy_text, if: :managed?)
    custom_attribute(:dac_policy_title, default: configatron.default_policy_title, if: :managed?)
    custom_attribute(:ega_dac_accession_number)
    custom_attribute(:ega_policy_accession_number)
    custom_attribute(:array_express_accession_number)

    with_options(if: :never_release?) do
      custom_attribute(
        :data_release_prevention_reason,
        in: [*DATA_RELEASE_PREVENTION_REASONS, *OLD_DATA_RELEASE_PREVENTION_REASONS],
        required: true
      )
      custom_attribute(
        :data_release_prevention_other_comment,
        required: true,
        if: :data_release_prevention_reason_other?
      )
      custom_attribute(:data_release_prevention_reason_comment)
      custom_attribute(:data_release_prevention_approval)
    end

    # NOTE: Additional validation in Study::Metadata Class to validate_presence_of :data_access_group, if: :managed
    # Behaviour can't go here, as :if also toggles the saving of the required information.
    custom_attribute(:data_access_group, with: /\A[a-z_][a-z0-9_-]{0,31}(?:\s+[a-z_][a-z0-9_-]{0,31})*\Z/)

    # SNP information
    custom_attribute(:snp_study_id, integer: true)
    custom_attribute(:snp_parent_study_id, integer: true)

    custom_attribute(:number_of_gigabases_per_sample)

    custom_attribute(:hmdmc_approval_number)

    # External Customers
    custom_attribute(:s3_email_list)
    custom_attribute(:data_deletion_period)
    custom_attribute(:contaminated_human_data_access_group)

    REMAPPED_ATTRIBUTES =
      {
        contaminated_human_dna: YES_OR_NO,
        remove_x_and_autosomes: YES_OR_NO,
        study_sra_hold: STUDY_SRA_HOLDS,
        contains_human_dna: YES_OR_NO,
        commercially_available: YES_OR_NO
      }.transform_values { |v| v.index_by { |b| b.downcase } }

    # These fields are warehoused, so need to match the encoding restrictions there
    # This excludes supplementary characters, which include emoji and rare kanji
    validates :study_abstract, :study_study_title, :study_description, :s3_email_list, utf8mb3: true

    validates :data_release_delay_other_comment, length: { maximum: 255 }

    # These fields are restricted further as they aren't expected to ever contain anything more than ASCII
    validates :study_project_id,
              :ega_dac_accession_number,
              :ega_policy_accession_number,
              :study_ebi_accession_number,
              :array_express_accession_number,
              :hmdmc_approval_number,
              format: {
                with: /\A[[:ascii:]]+\z/,
                message: 'only allows ASCII',
                allow_blank: true
              }

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

  validates_associated :study_metadata, on: %i[accession EGA ENA]

  # See app/models/study/metadata.rb for further customization

  # Scopes
  scope :for_search_query,
        ->(query) do
          joins(:study_metadata).where(['name LIKE ? OR studies.id=? OR prelim_id=?', "%#{query}%", query, query])
        end

  scope :with_no_ethical_approval, -> { where(ethically_approved: false) }

  scope :is_active, -> { where(state: 'active') }
  scope :is_inactive, -> { where(state: 'inactive') }
  scope :is_pending, -> { where(state: 'pending') }

  scope :newest_first, -> { order(created_at: :desc) }
  scope :with_user_included, -> { includes(:user) }

  scope :in_assets,
        ->(assets) do
          select('DISTINCT studies.*').joins(['LEFT JOIN aliquots ON aliquots.study_id = studies.id']).where(
            ['aliquots.receptacle_id IN (?)', assets.map(&:id)]
          )
        end

  scope :for_sample_accessioning,
        -> do
          joins(:study_metadata).where("study_metadata.study_ebi_accession_number <> ''").where(
            study_metadata: {
              data_release_strategy: [Study::DATA_RELEASE_STRATEGY_OPEN, Study::DATA_RELEASE_STRATEGY_MANAGED],
              data_release_timing: Study::DATA_RELEASE_TIMINGS
            }
          )
        end

  scope :awaiting_ethical_approval,
        -> do
          joins(:study_metadata).where(
            ethically_approved: false,
            study_metadata: {
              contains_human_dna: Study::YES,
              contaminated_human_dna: Study::NO,
              commercially_available: Study::NO
            }
          )
        end

  scope :contaminated_with_human_dna,
        -> { joins(:study_metadata).where(study_metadata: { contaminated_human_dna: Study::YES }) }

  scope :with_remove_x_and_autosomes,
        -> { joins(:study_metadata).where(study_metadata: { remove_x_and_autosomes: Study::YES }) }

  scope :by_state, ->(state) { where(state:) }

  scope :by_user,
        ->(login) do
          joins(:roles, :users).where(roles: { name: %w[follower manager owner], users: { login: [login] } })
        end

  scope :with_related_owners_included, -> { includes(:owners) }

  # Delegations
  alias_attribute :friendly_name, :name

  delegate :data_release_strategy, to: :study_metadata

  # Class Methods

  # Instance methods

  def validate_ethically_approved
    return true if valid_ethically_approved?

    message =
      if ethical_approval_required?
        'should be either true or false for this study.'
      else
        'should be not applicable (null) not false.'
      end
    errors.add(:ethically_approved, message)
    false
  end

  def each_well_for_qc_report_in_batches(exclude_existing, product_criteria, plate_purposes = nil)
    # @note We include aliquots here, despite the fact they are only needed if we have to set a poor-quality flag
    #       as in some cases failures are not as rare as you may imagine, and it can cause major performance issues.
    base_scope =
      Well
        .on_plate_purpose_included(PlatePurpose.where(name: plate_purposes || STOCK_PLATE_PURPOSES))
        .for_study_through_aliquot(self)
        .without_blank_samples
        .includes(:well_attribute, :aliquots, :map, samples: :sample_metadata)
        .readonly(true)
    scope = exclude_existing ? base_scope.without_report(product_criteria) : base_scope
    scope.find_in_batches { |wells| yield wells }
  end

  def warnings
    # These studies are now invalid, but the warning should remain until existing studies are fixed.
    if study_metadata.managed? && study_metadata.data_access_group.blank?
      # rubocop:todo Layout/LineLength
      'No user group specified for a managed study. Please specify a valid Unix user group to ensure study data is visible to the correct people.'
      # rubocop:enable Layout/LineLength
    end
  end

  def mark_deactive
    logger.warn "Study deactivation failed! #{errors.map(&:to_s)}" unless inactive?
  end

  def mark_active
    logger.warn "Study activation failed! #{errors.map(&:to_s)}" unless active?
  end

  def text_comments
    comments.each_with_object([]) { |c, array| array << c.description if c.description.present? }.join(', ')
  end

  def completed
    counts = requests.standard.group('state').count
    total = counts.values.sum
    failed = counts['failed'] || 0
    cancelled = counts['cancelled'] || 0
    (total - failed - cancelled) > 0 ? (counts.fetch('passed', 0) * 100) / (total - failed - cancelled) : 0
  end

  # Yields information on the state of all request types in a convenient fashion for displaying in a table.
  # Used initial requests, which won't capture cross study sequencing requests.
  def request_progress
    yield(@stats_cache ||= initial_requests.progress_statistics) if block_given?
  end

  # Yields information on the state of all assets in a convenient fashion for displaying in a table.
  def asset_progress(assets = nil)
    wheres = {}
    wheres = { asset_id: assets.map(&:id) } if assets.present?
    yield(initial_requests.asset_statistics(wheres))
  end

  # Yields information on the state of all samples in a convenient fashion for displaying in a table.
  def sample_progress(samples = nil)
    if samples.blank?
      requests.sample_statistics_new
    else
      # Rubocop suggests this changes as it allows MySQL to perform a single query, which is usually better
      # however in this case we've actually already loaded the samples. If we do try passing in the
      # samples themselves, then things top working as intended. (Performance tanks in some places, and
      # we generate invalid SQL in others)
      yield(requests.where(aliquots: { sample_id: samples.pluck(:id) }).sample_statistics_new)
    end
  end

  def study_status
    inactive? ? 'closed' : 'open'
  end

  def dac_refname
    "DAC for study - #{name} - ##{id}"
  end

  def unprocessed_submissions?
    # TODO[mb14] optimize if needed
    study.orders.any? { |o| o.submission.nil? || o.submission.unprocessed? }
  end

  # Used by EventfulMailer
  def study
    self
  end

  # Returns the study owner (user) if exists or nil
  # TODO - Should be "owners" and return all owners or empty array - done
  # TODO - Look into this is the person that created it really the owner?
  # If so, then an owner should be created when a study is created.

  def owner
    owners.first
  end

  def locale
    funding_source
  end

  def ebi_accession_number
    study_metadata.study_ebi_accession_number
  end

  def dac_accession_number
    study_metadata.ega_dac_accession_number
  end

  def policy_accession_number
    study_metadata.ega_policy_accession_number
  end

  def accession_number?
    ebi_accession_number.present?
  end

  def accession_all_samples
    samples.find_each(&:accession) if accession_number?
  end

  def abbreviation
    abbreviation = study_metadata.study_name_abbreviation
    abbreviation.presence || "#{id}STDY"
  end

  def dehumanise_abbreviated_name
    abbreviation.downcase.gsub(/ +/, '_')
  end

  def approved?
    # TODO: remove
    true
  end

  def ethical_approval_required?
    study_metadata.contains_human_dna == Study::YES && study_metadata.contaminated_human_dna == Study::NO &&
      study_metadata.commercially_available == Study::NO
  end

  def accession_service
    case data_release_strategy
    when 'open'
      EnaAccessionService.new
    when 'managed'
      EgaAccessionService.new
    else
      NoAccessionService.new(self)
    end
  end

  def send_samples_to_service?
    accession_service.no_study_accession_needed || (!study_metadata.never_release? && accession_number?)
  end

  def validate_ena_required_fields!
    valid?(:accession) or raise ActiveRecord::RecordInvalid, self
  end

  def mailing_list_of_managers
    configured_managers = managers.pluck(:email).compact.uniq
    configured_managers.empty? ? configatron.fetch(:ssr_emails, User.all_administrators_emails) : configured_managers
  end

  def subject_type
    'study'
  end

  def rebroadcast
    broadcast
  end

  # Helper method for edit dropdowns to support backwards compatibility with old options.
  #
  # @return [Array<String>] the list of options for the data release prevention reason dropdown
  def data_release_prevention_options
    additional_options = []
    if OLD_DATA_RELEASE_PREVENTION_REASONS.include? study_metadata.data_release_prevention_reason
      additional_options << study_metadata.data_release_prevention_reason
    end

    DATA_RELEASE_PREVENTION_REASONS + additional_options
  end

  # Helper method for edit dropdowns to support backwards compatibility with old options.
  #
  # @param [Boolean] assay_option - whether to include assay-specific options
  # @return [Array<String>] the list of options for the data release delay reason dropdown
  def data_release_delay_options(assay_option: false)
    # If the current value is an old one, then we need to include it in the list of options
    additional_options = []
    if OLD_DATA_RELEASE_DELAY_REASONS.include? study_metadata.data_release_delay_reason
      additional_options << study_metadata.data_release_delay_reason
    end

    additional_options.concat(DATA_RELEASE_DELAY_REASONS_ASSAY) if assay_option
    DATA_RELEASE_DELAY_REASONS_STANDARD + additional_options
  end

  private

  def valid_ethically_approved?
    ethical_approval_required? ? !ethically_approved.nil? : ethically_approved != false
  end

  def set_default_ethical_approval
    self.ethically_approved ||= ethical_approval_required? ? false : nil
  end

  class Metadata
    delegate :enforce_data_release, to: :study

    def remove_x_and_autosomes?
      remove_x_and_autosomes == YES
    end

    def managed?
      data_release_strategy == DATA_RELEASE_STRATEGY_MANAGED
    end

    def strategy_not_applicable?
      data_release_strategy == DATA_RELEASE_STRATEGY_NOT_APPLICABLE
    end

    def delayed_release?
      data_release_timing == DATA_RELEASE_TIMING_DELAYED
    end

    def never_release?
      data_release_timing == DATA_RELEASE_TIMING_NEVER
    end

    def delayed_for_other_reasons?
      [DATA_RELEASE_DELAY_FOR_OTHER, OLD_DATA_RELEASE_DELAY_FOR_OTHER].include?(data_release_delay_reason)
    end

    def data_release_prevention_reason_other?
      data_release_prevention_reason == DATA_RELEASE_PREVENTION_REASON_OTHER
    end

    def delayed_for_long_time?
      DATA_RELEASE_DELAY_PERIODS.include?(data_release_delay_period)
    end

    def delay_until_publication?
      data_release_timing == DATA_RELEASE_TIMING_PUBLICATION
    end

    validates :number_of_gigabases_per_sample, numericality: { greater_than_or_equal_to: 0.15, allow_blank: true }

    has_one :data_release_non_standard_agreement, class_name: 'Document', as: :documentable
    accepts_nested_attributes_for :data_release_non_standard_agreement
    validates :data_release_non_standard_agreement, presence: true, if: :non_standard_agreement?
    validates_associated :data_release_non_standard_agreement, if: :non_standard_agreement?

    # Please adjust comment above if this behaviour ever changes
    validates :data_access_group, presence: { if: :managed? }

    validate :valid_policy_url?

    validate :sanity_check_y_separation, if: :separate_y_chromosome_data?

    validates :data_release_timing, inclusion: { in: DATA_RELEASE_TIMINGS }, if: :data_release_timing_must_not_be_never?
    validates :data_release_timing,
              inclusion: {
                in: [DATA_RELEASE_TIMING_NEVER]
              },
              if: :data_release_timing_must_be_never?

    def data_release_timing_must_be_never?
      Flipper.enabled?(:y24_052_enable_data_release_timing_validation) && data_release_strategy.present? &&
        strategy_not_applicable?
    end

    def data_release_timing_must_not_be_never?
      Flipper.enabled?(:y24_052_enable_data_release_timing_validation) && data_release_strategy.present? &&
        !strategy_not_applicable?
    end

    def sanity_check_y_separation
      if remove_x_and_autosomes?
        errors.add(:separate_y_chromosome_data, 'cannot be selected with remove x and autosomes.')
      end
      !remove_x_and_autosomes?
    end

    before_validation do |record|
      if !record.non_standard_agreement? && !record.data_release_non_standard_agreement.nil?
        record.data_release_non_standard_agreement.delete
        record.data_release_non_standard_agreement = nil
      end
    end

    def non_standard_agreement?
      data_release_standard_agreement == NO
    end

    def study_type_valid?
      errors.add(:study_type, 'is not specified') if study_type.name == 'Not specified'
    end

    # rubocop:todo Metrics/MethodLength
    def valid_policy_url? # rubocop:todo Metrics/AbcSize
      # Rails 2.3 has no inbuilt URL validation, but rather than rolling our own, we'll
      # use the inbuilt ruby URI parser, a bit like here:
      # http://www.simonecarletti.com/blog/2009/04/validating-the-format-of-an-url-with-rails/
      return true if dac_policy.blank?

      dac_policy.insert(0, 'http://') unless dac_policy.include?('://') # Add an http protocol if no protocol is defined
      begin
        uri = URI.parse(dac_policy)
        if configatron.invalid_policy_url_domains.include?(uri.host)
          errors.add(
            :dac_policy,
            ": #{dac_policy} is not an acceptable URL. Please ensure you haven't provided an internal URL."
          )
        end
      rescue URI::InvalidURIError
        errors.add(:dac_policy, ": #{dac_policy} is not a valid URL")
      end
    end

    # rubocop:enable Metrics/MethodLength

    with_options(on: :accession, if: :enforce_data_release) do
      validates :data_release_strategy, presence: true
      validates :data_release_timing, presence: true
      validates :study_description, presence: true
      validates :study_abstract, presence: true
      validates :study_study_title, presence: true
      validate :study_type_valid?
    end

    def snp_parent_study
      return nil if snp_parent_study_id.nil?

      self.class.where(snp_study_id: snp_parent_study_id).includes(:study).try(:study)
    end

    def snp_child_studies
      return nil if snp_study_id.nil?

      self.class.where(snp_parent_study_id: snp_study_id).includes(:study).map(&:study)
    end
  end
end
