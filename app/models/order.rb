# frozen_string_literal: true

# An Order is used as the main means of requesting work in Sequencescape. Its
# key components are:
# Assets/AssetGroup: The assets on which the work will be conducted
# Study: The study for which work is being undertaken
# Project: The project who will be charged for the work
# Request options: The parameters for the request which will be built. eg. read length
# Request Types: An array of request type ids which will be built by the order.
#                This is populated based on the submission template used.
# Submission: Multiple orders may be grouped together in a submission. This
#             associates the two sets of requests, and is usually used to determine
#             what gets pooled together during multiplexing. As a result, sequencing
#             requests may be shared between multiple orders.
class Order < ApplicationRecord # rubocop:todo Metrics/ClassLength
  # Ensure order methods behave correctly
  AssetTypeError = Class.new(StandardError)
  DEFAULT_ASSET_INPUT_METHODS = ['select an asset group'].freeze

  include Uuid::Uuidable
  include Submission::AssetGroupBehaviour
  include Submission::ProjectValidation
  include Submission::RequestOptionsBehaviour
  include Submission::AccessionBehaviour

  self.inheritance_column = 'sti_type'
  self.per_page = 500

  #  attributes which are not saved for a submission but can be pre-set via SubmissionTemplate
  # return a list of request_types lists  (a sequence of choices) to display in the new view
  attr_writer :request_type_ids_list, :input_field_infos
  attr_writer :asset_input_methods

  # Unused. Maintained because some submission templates attempt to set the info
  attr_writer :info_differential

  # When automating submission creation, it is really useful if we can
  # auto-detect studies and projects based on their aliquots. However we
  # don't want to trigger this behaviour accidentally if someone forgets to
  # specify a study.
  attribute :autodetect_studies, :boolean, default: :autodetection_default
  attribute :autodetect_projects, :boolean, default: :autodetection_default

  # Required at initial construction time ...
  belongs_to :study, optional: true
  belongs_to :project, optional: true
  belongs_to :user, optional: false
  belongs_to :product, optional: true
  belongs_to :order_role, optional: true
  belongs_to :submission, inverse_of: :orders

  # In the case of some cross study/project orders, such as resequencing of
  # mixed pools, there is no study/project on the order itself.
  # In some cases, such as viewing submission, it can be useful to display
  # the associated studies/projects
  has_many :source_asset_studies, -> { distinct }, through: :assets, source: :studies
  has_many :source_asset_projects, -> { distinct }, through: :assets, source: :projects
  has_many :requests, inverse_of: :order, dependent: :restrict_with_exception

  serialize :request_types, coder: YAML
  serialize :item_options, coder: YAML

  before_validation :set_study_from_aliquots, unless: :cross_study_allowed, if: :autodetect_studies
  before_validation :set_project_from_aliquots, unless: :cross_project_allowed, if: :autodetect_projects

  validates :study, presence: true, unless: :cross_study_allowed
  validates :project, presence: true, unless: :cross_project_allowed
  validates :request_types, presence: true

  validate :study_is_active, on: :create
  validate :assets_are_appropriate
  validate :no_consent_withdrawal

  before_destroy :building_submission?
  after_destroy :on_delete_destroy_submission

  broadcast_with_warren

  scope :include_for_study_view, -> { includes(:submission) }
  scope :containing_samples, ->(samples) { joins(assets: :samples).where(samples: { id: samples }) }
  scope :for_studies, ->(*args) { where(study_id: args) }

  scope :including_associations_for_json,
        lambda {
          includes(
            [:uuid_object, { assets: [:uuid_object] }, { project: :uuid_object }, { study: :uuid_object }, :user]
          )
        }

  has_many :submitted_assets, -> { joins(:asset) }, inverse_of: :order
  has_many :assets, through: :submitted_assets, before_add: :validate_new_record do
    def <<(associated)
      return super if associated.is_a?(Receptacle)

      Rails.logger.warn("#{associated.class.name} passed to order.assets")
      super(associated&.receptacle)
    end
  end

  delegate :role, to: :order_role, allow_nil: true

  class << self
    alias create_order! create!

    def render_class
      Api::OrderIo
    end
  end

  def autodetection_default
    false
  end

  def complete_building
    check_project_details!
    complete_building_asset_group
  end

  def assets=(assets_to_add)
    assets_to_add.map { |a| a.is_a?(Receptacle) ? a : a.receptacle }
  end

  # We can't destroy orders once the submission has been finalized for building
  def building_submission?
    throw :abort unless submission.building?
  end

  def on_delete_destroy_submission
    if building_submission?
      # After destroying an order, if it is the last order on it's submission
      # destroy the submission too.
      orders = submission.orders
      submission.destroy unless orders.size > 1
      return true
    end
    false
  end

  def cross_study_allowed
    false
  end

  def cross_project_allowed
    false
  end

  def cross_compatible?
    false
  end

  # TODO: Figure out why eager loading aliquots/samples returns [] even when
  # we limit order_assets to receptacles.
  def samples
    # naive way
    assets.map(&:samples).flatten.uniq
  end

  def all_samples
    # slightly less naive way
    all_assets.map(&:samples).flatten.uniq
  end

  def all_assets
    pull_assets_from_asset_group if assets.empty? && asset_group.present?
    assets
  end

  def json_root
    'order'
  end

  def asset_uuids
    assets&.select(&:present?)&.map(&:uuid)
  end

  def multiplexed?
    RequestType.where(id: request_types).for_multiplexing.exists?
  end

  def multiplier_for(request_type_id)
    (request_options.dig(:multiplier, request_type_id.to_s) || 1).to_i
  end

  # Determines and returns calculated request metadata based on the request type key.
  # This is to cover calculated metadata that does not require user input
  def calculated_request_metadata_by_request_key(request_type_key)
    case request_type_key
    # Checking for the presence of allowance_band, as it is calculated for
    # the bulk submission only
    when 'limber_scrna_core_cdna_prep_gem_x_5p'
      request_options['allowance_band'].present? ? { 'allowance_band' => request_options['allowance_band'] } : {}
    else
      {}
    end
  end

  # rubocop:todo Metrics/MethodLength
  def create_request_of_type!(request_type, attributes = {}) # rubocop:todo Metrics/AbcSize
    request_metadata = request_type.extract_metadata_from_hash(request_options)
    request_metadata = request_metadata.merge(calculated_request_metadata_by_request_key(request_type.key))
    request_type.create!(attributes) do |request|
      request.submission_id = submission_id
      request.study = study
      request.initial_project = project
      request.user = user
      request.request_metadata_attributes = request_metadata
      request.state = request_type.initial_state
      request.order = self

      if request.asset.present?
        unless asset_applicable_to_type?(request_type, request.asset)
          raise AssetTypeError, 'Asset type does not match that expected by request type.'
        end
      end
    end
  end

  # rubocop:enable Metrics/MethodLength

  def duplicates_within(timespan) # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    matching_orders =
      Order
        .containing_samples(all_samples)
        .where(template_name:)
        .includes(:submission, assets: :samples)
        .where.not(orders: { id: })
        .where('orders.created_at > ?', Time.current - timespan)
    return false if matching_orders.empty?

    matching_samples = matching_orders.map(&:samples).flatten & all_samples
    matching_submissions = matching_orders.map(&:submission).uniq
    yield matching_samples, matching_orders, matching_submissions if block_given?
    true
  end

  def request_type_ids_list
    @request_type_ids_list ||= [[]]
  end

  def asset_input_methods
    @asset_input_methods ||= DEFAULT_ASSET_INPUT_METHODS
  end

  # request_type_ids_list is set for orders created by submission templates
  # It is used by the input_field_infos section, which controls rendering
  # form fields appropriate to each request type in the submission interface
  # {request_type_ids} is calculated from this in the various sub-classes
  # and gets persisted to the database, and used for the actual construction.
  # TODO: Simplify this
  # - There are a few attributes which all refer to loosely the same thing, a list of request type ids:
  #   * request_type_ids_list - Set by submission templates, but also recalculated on the fly and used in various
  #                             methods
  #   * request_types_ids - Setter on order subclasses.
  #   * request_types - Serialized version on order, persisted in the database
  # - The request_types on the database should become the authoritative source.
  # - request_type_ids_list should just be a setter, which populates request_types.
  #   It may need to transform the input slightly. Ideally we eliminate this entirely, and be consistent between
  #   templates and orders
  # - There appear to be several methods which essentially do the same thing. They should be unified.
  # - I'm not even 100% how request_types_ids factors in.
  def request_types_list
    request_type_ids_list.map { |ids| RequestType.find(ids) }
  end

  def first_request_type
    @first_request_type ||= RequestType.find(request_types.first)
  end

  def request_type_multiplier
    yield(request_types.last.to_s.to_sym) if request_types.present?
  end

  # Return the list of input fields to edit when creating a new submission
  # Unless you are doing something fancy, fall back on the defaults
  def input_field_infos
    @input_field_infos ||= FieldInfo.for_request_types(request_types_list.flatten)
  end

  def next_request_type_id(request_type_id)
    request_type_ids = request_types.map(&:to_i)
    request_type_ids[request_type_ids.index(request_type_id) + 1]
  end

  # Are we still able to modify this instance?
  def building?
    submission.nil?
  end

  # Returns true if this is an order for sequencing
  def sequencing_order?
    RequestType.find(request_types).any?(&:sequencing?)
  end

  def collect_gigabases_expected?
    input_field_infos.any? { |k| k.key == :gigabases_expected }
  end

  def add_comment(comment_str, user)
    update!(comments: [comments, comment_str].compact.join('; '))

    submission
      .requests
      .for_order_including_submission_based_requests(self)
      .map { |request| request.add_comment(comment_str, user) }
  end

  def friendly_name
    asset_group.try(:name) || asset_group_name || id
  end

  def subject_type
    'order'
  end

  def generate_broadcast_event
    BroadcastEvent::OrderMade.create!(seed: self, user: user)
  end

  def study_is_active
    errors.add(:study, 'is not active') if study.present? && !study.active?
  end

  # returns an array of samples, that potentially can not be included in submission
  def not_ready_samples
    all_samples.reject(&:can_be_included_in_submission?)
  end

  private

  def asset_applicable_to_type?(request_type, asset)
    request_type.asset_type == asset.asset_type_for_request_types.name
  end

  def no_consent_withdrawal
    return true unless all_samples.any?(&:consent_withdrawn?)

    withdrawn_samples = all_samples.select(&:consent_withdrawn?).map(&:friendly_name)
    errors.add(:samples, "in this submission have had patient consent withdrawn: #{withdrawn_samples.to_sentence}")
    false
  end

  def assets_are_appropriate
    all_assets.each do |asset|
      next if asset_applicable_to_type?(first_request_type, asset)

      errors.add(
        :asset,
        "'#{asset.display_name}' is a #{asset.sti_type} which is not suitable for #{first_request_type.name} requests"
      )
    end
    return true if errors.empty?

    false
  end

  def set_study_from_aliquots
    studies = assets.reduce(Set.new) { |set, asset| set.merge(asset.studies) }
    self.study ||= studies.first if studies.one?
  end

  def set_project_from_aliquots
    projects = assets.reduce(Set.new) { |set, asset| set.merge(asset.projects) }
    self.project ||= projects.first if projects.one?
  end
end
