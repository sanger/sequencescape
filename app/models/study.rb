# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

require 'aasm'

class Study < ApplicationRecord
  # It has to be here, as there are has_many through: :roles associations in modules
  # Includes / Extendes
  has_many :roles
  # Includes / Extendes
  include StudyReport::StudyDetails
  include ModelExtensions::Study
  include Api::StudyIO::Extensions
  include Uuid::Uuidable
  include EventfulRecord
  include AASM
  include DataRelease
  include Commentable
  include Identifiable
  include SharedBehaviour::Named
  include ReferenceGenome::Associations
  include SampleManifest::Associations
  include Request::Statistics::DeprecatedMethods
  include Role::Authorized
  include StudyRelation::Associations

  extend EventfulRecord
  extend Metadata

  # Constants
  STOCK_PLATE_PURPOSES = ['Stock Plate', 'Stock RNA Plate']
  YES = 'Yes'
  NO  = 'No'
  YES_OR_NO = [YES, NO]
  Other_type = 'Other'

  STUDY_SRA_HOLDS = ['Hold', 'Public']

  DATA_RELEASE_STRATEGY_OPEN = 'open'
  DATA_RELEASE_STRATEGY_MANAGED = 'managed'
  DATA_RELEASE_STRATEGY_NOT_APPLICABLE = 'not applicable'
  DATA_RELEASE_STRATEGIES = [DATA_RELEASE_STRATEGY_OPEN, DATA_RELEASE_STRATEGY_MANAGED, DATA_RELEASE_STRATEGY_NOT_APPLICABLE]

  DATA_RELEASE_TIMING_STANDARD = 'standard'
  DATA_RELEASE_TIMING_NEVER    = 'never'
  DATA_RELEASE_TIMING_DELAYED  = 'delayed'
  DATA_RELEASE_TIMINGS = [
    DATA_RELEASE_TIMING_STANDARD,
    'immediate',
    DATA_RELEASE_TIMING_DELAYED
  ]
  DATA_RELEASE_PREVENTION_REASONS = [
    'data validity',
    'legal',
    'replication of data subset'
  ]

  DATA_RELEASE_DELAY_FOR_OTHER = 'other'
  DATA_RELEASE_DELAY_REASONS_STANDARD = [
    'phd study',
    DATA_RELEASE_DELAY_FOR_OTHER
  ]
  DATA_RELEASE_DELAY_REASONS_ASSAY = [
    'phd study',
    'assay of no other use',
    DATA_RELEASE_DELAY_FOR_OTHER
  ]

  DATA_RELEASE_DELAY_LONG  = ['6 months', '9 months', '12 months', '18 months']
  DATA_RELEASE_DELAY_SHORT = ['3 months']
  DATA_RELEASE_DELAY_PERIODS = DATA_RELEASE_DELAY_SHORT + DATA_RELEASE_DELAY_LONG

  # Class variables
  self.per_page = 500

  attr_accessor :approval
  attr_accessor :run_count
  attr_accessor :total_price

  # Associations
  has_many_events
  has_many_lab_events

  role_relation(:followed_by,       'follower')
  role_relation(:managed_by,        'manager')
  role_relation(:collaborated_with, 'collaborator')

  belongs_to :user

  has_many :data_access_contacts, ->() { where(roles: { name: 'Data Access Contact' }) }, through: :roles, source: :users
  has_many :followers, ->() { where(roles: { name: 'follower' }) }, through: :roles, source: :users
  has_many :managers, ->() { where(roles: { name: 'manager' }) }, through: :roles, source: :users
  has_many :owners, ->() { where(roles: { name: 'owner' }) }, through: :roles, source: :users
  has_many :study_samples, inverse_of: :study
  has_many :orders
  has_many :submissions, through: :orders
  has_many :samples, through: :study_samples, inverse_of: :studies
  has_many :batches
  has_many :asset_groups
  has_many :study_reports
  # load all the associated requests with attemps and request type
  has_many :eager_items, ->() { includes(requests: :request_type) }, class_name: 'Item', through: :requests, source: :item
  has_many :aliquots
  has_many :initial_requests, class_name: 'Request', foreign_key: :initial_study_id
  has_many :assets_through_aliquots,  ->() { distinct }, class_name: 'Asset', through: :aliquots, source: :receptacle
  has_many :assets_through_requests,  ->() { distinct }, class_name: 'Asset', through: :initial_requests, source: :asset
  has_many :requests, through: :assets_through_aliquots, source: :requests_as_source
  has_many :items, ->() { distinct }, through: :requests
  has_many :projects, ->() { distinct }, through: :orders
  has_many :comments, as: :commentable
  has_many :events, ->() { order('created_at ASC, id ASC') }, as: :eventful
  has_many :documents, as: :documentable
  has_many :sample_manifests
  has_many :suppliers, ->() { distinct }, through: :sample_manifests

  # Validations
  validates_presence_of :name
  validates :name, on: :create, uniqueness: { case_sensitive: false }
  validates_length_of :name, maximum: 200
  validates_format_of :abbreviation, with: /\A[\w_-]+\z/i, allow_blank: false, message: 'cannot contain spaces or be blank'
  validate :validate_ethically_approved

  # Callbacks
  before_validation :set_default_ethical_approval
  after_touch :rebroadcast

  # Other class methods / DSL
  acts_as_authorizable

  aasm column: :state, whiny_persistence: true do
    state :pending, initial: true
    state :active, enter: :mark_active
    state :inactive, enter: :mark_deactive

    event :reset do
      transitions to: :pending, from: [:inactive, :active]
    end

    event :activate do
      transitions to: :active, from: [:pending, :inactive]
    end

    event :deactivate do
      transitions to: :inactive, from: [:pending, :active]
    end
  end

  broadcast_via_warren

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

    custom_attribute(:data_release_strategy, required: true, in: DATA_RELEASE_STRATEGIES, default: DATA_RELEASE_STRATEGY_MANAGED)
    custom_attribute(:data_release_standard_agreement, default: YES, in: YES_OR_NO, if: :managed?)

    custom_attribute(:data_release_timing, required: true, default: DATA_RELEASE_TIMING_STANDARD, in: DATA_RELEASE_TIMINGS + [DATA_RELEASE_TIMING_NEVER])
    custom_attribute(:data_release_delay_reason, required: true, in: DATA_RELEASE_DELAY_REASONS_ASSAY, if: :delayed_release?)
    custom_attribute(:data_release_delay_period, required: true, in: DATA_RELEASE_DELAY_PERIODS, if: :delayed_release?)
    custom_attribute(:bam, default: true)

    with_options(required: true, if: :delayed_for_other_reasons?) do |required|
      required.custom_attribute(:data_release_delay_other_comment)
      required.custom_attribute(:data_release_delay_reason_comment)
    end

    custom_attribute(:dac_policy, default: configatron.default_policy_text, if: :managed?)
    custom_attribute(:dac_policy_title, default: configatron.default_policy_title, if: :managed?)
    custom_attribute(:ega_dac_accession_number)
    custom_attribute(:ega_policy_accession_number)
    custom_attribute(:array_express_accession_number)

    with_options(if: :delayed_for_long_time?, required: true) do |required|
      required.custom_attribute(:data_release_delay_approval, in: YES_OR_NO, default: NO)
    end

    with_options(if: :never_release?, required: true) do |required|
      required.custom_attribute(:data_release_prevention_reason, in: DATA_RELEASE_PREVENTION_REASONS)
      required.custom_attribute(:data_release_prevention_approval, in: YES_OR_NO)
      required.custom_attribute(:data_release_prevention_reason_comment)
    end

    # Note: Additional validation in Study::Metadata Class to validate_presence_of :data_access_group, if: :managed
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

    REMAPPED_ATTRIBUTES = {
      contaminated_human_dna: YES_OR_NO,
      remove_x_and_autosomes: YES_OR_NO,
      study_sra_hold: STUDY_SRA_HOLDS,
      contains_human_dna: YES_OR_NO,
      commercially_available: YES_OR_NO
    }.each_with_object({}) do |(k, v), h|
      h[k] = v.each_with_object({}) { |b, a| a[b.downcase] = b }
    end

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

  # See app/models/study/metadata.rb for further customization

  # Scopes
  scope :for_search_query, ->(query, _with_includes) {
                             joins(:study_metadata).where(['name LIKE ? OR studies.id=? OR prelim_id=?', "%#{query}%", query, query])
                           }

  scope :with_no_ethical_approval, -> { where(ethically_approved: false) }

  scope :is_active,   -> { where(state: 'active') }
  scope :is_inactive, -> { where(state: 'inactive') }
  scope :is_pending,  -> { where(state: 'pending') }

  scope :newest_first, -> { order("#{quoted_table_name}.created_at DESC") }
  scope :with_user_included, -> { includes(:user) }

  scope :in_assets, ->(assets) {
    select('DISTINCT studies.*')
      .joins([
        'LEFT JOIN aliquots ON aliquots.study_id = studies.id',
      ])
      .where(['aliquots.receptacle_id IN (?)', assets.map(&:id)])
  }

  scope :for_sample_accessioning, ->() {
    joins(:study_metadata)
      .where("study_metadata.study_ebi_accession_number <> ''")
      .where(study_metadata: { data_release_strategy: [Study::DATA_RELEASE_STRATEGY_OPEN, Study::DATA_RELEASE_STRATEGY_MANAGED], data_release_timing: Study::DATA_RELEASE_TIMINGS })
  }

  scope :awaiting_ethical_approval, ->() {
    joins(:study_metadata)
      .where(
        ethically_approved: false,
        study_metadata: {
          contains_human_dna: Study::YES,
          contaminated_human_dna: Study::NO,
          commercially_available: Study::NO
        }
      )
  }

  scope :contaminated_with_human_dna, ->() {
    joins(:study_metadata)
      .where(
        study_metadata: {
          contaminated_human_dna: Study::YES
        }
      )
  }

  scope :with_remove_x_and_autosomes, ->() {
    joins(:study_metadata)
      .where(
        study_metadata: {
          remove_x_and_autosomes: Study::YES
        }
      )
  }

  scope :by_state, ->(state) { where(state: state) }

  scope :by_user, ->(login) { joins(:roles, :users).where(roles: { name: ['follower', 'manager', 'owner'], users: { login: [login] } }) }

  # Delegations
  alias_attribute :friendly_name, :name

  delegate :data_release_strategy, to: :study_metadata

  # Class Methods

  # Instance methods

  def validate_ethically_approved
    return true if valid_ethically_approved?
    message = ethical_approval_required? ? 'should be either true or false for this study.' : 'should be not applicable (null) not false.'
    errors.add(:ethically_approved, message)
    false
  end

  def each_well_for_qc_report_in_batches(exclude_existing, product_criteria, plate_purposes = nil)
    base_scope = Well.on_plate_purpose(PlatePurpose.where(name: plate_purposes || STOCK_PLATE_PURPOSES))
                     .for_study_through_aliquot(self)
                     .without_blank_samples
                     .includes(:well_attribute, samples: :sample_metadata)
                     .readonly(true)
    scope = exclude_existing ? base_scope.without_report(product_criteria) : base_scope
    scope.find_in_batches { |wells| yield wells }
  end

  # We only need to validate the field if we are enforcing data release
  def validating_ena_required_fields_with_enforce_data_release=(state)
    self.validating_ena_required_fields_without_enforce_data_release = state if enforce_data_release
  end
  alias validating_ena_required_fields_with_enforce_data_release= validating_ena_required_fields=
  alias validating_ena_required_fields= validating_ena_required_fields_with_enforce_data_release=

  def warnings
    # These studies are now invalid, but the warning should remain until existing studies are fixed.
    if study_metadata.managed? && study_metadata.data_access_group.blank?
      'No user group specified for a managed study. Please specify a valid Unix user group to ensure study data is visible to the correct people.'
    end
  end

  def mark_deactive
    unless inactive?
      logger.warn "Study deactivation failed! #{errors.map { |e| e.to_s }}"
    end
  end

  def mark_active
    unless active?
      logger.warn "Study activation failed! #{errors.map { |e| e.to_s }}"
    end
  end

  def text_comments
    comments.each_with_object([]) { |c, array| array << c.description unless c.description.blank? }.join(', ')
  end

  def completed(_workflow = nil)
    rts = RequestType.standard.pluck(:id)
    total = requests.request_type(rts).count
    failed = requests.failed.request_type(rts).count
    cancelled = requests.cancelled.request_type(rts).count
    if (total - failed - cancelled) > 0
      completed_percent = ((requests.passed.request_type(rts).count.to_f / (total - failed - cancelled).to_f) * 100)
      completed_percent.to_i
    else
      return 0
    end
  end

  # Yields information on the state of all request types in a convenient fashion for displaying in a table.
  def request_progress
    yield(initial_requests.progress_statistics)
  end

  # Yields information on the state of all assets in a convenient fashion for displaying in a table.
  def asset_progress(assets = nil)
    wheres = {}
    wheres = { asset_id: assets.map(&:id) } unless assets.blank?
    yield(initial_requests.asset_statistics(wheres))
  end

  # Yields information on the state of all samples in a convenient fashion for displaying in a table.
  def sample_progress(samples = nil)
    if samples.blank?
      requests.sample_statistics_new
    else
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
    if accession_number?
      samples.find_each do |sample|
        sample.accession
      end
    end
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
    (study_metadata.contains_human_dna == Study::YES &&
    study_metadata.contaminated_human_dna == Study::NO &&
    study_metadata.commercially_available == Study::NO)
  end

  def accession_service
    case data_release_strategy
    when 'open' then EnaAccessionService.new
    when 'managed' then EgaAccessionService.new
    else NoAccessionService.new(self)
    end
  end

  def send_samples_to_service?
    accession_service.no_study_accession_needed || ((!study_metadata.never_release?) && accession_number?)
  end

  def validate_ena_required_fields!
    self.validating_ena_required_fields = true
    valid? or raise ActiveRecord::RecordInvalid, self
  ensure
    self.validating_ena_required_fields = false
  end

  def mailing_list_of_managers
    configured_managers = managers.pluck(:email).compact.uniq
    if configured_managers.empty?
      configatron.fetch(:ssr_emails, User.all_administrators_emails)
    else
      configured_managers
    end
  end

  def subject_type
    'study'
  end

  def rebroadcast
    broadcast
  end

  private

  def valid_ethically_approved?
    ethical_approval_required? ? !ethically_approved.nil? : ethically_approved != false
  end

  def set_default_ethical_approval
    self.ethically_approved ||= ethical_approval_required? ? false : nil
    true
  end
end

require_dependency 'study/metadata'
