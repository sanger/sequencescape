# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015,2016 Genome Research Ltd.

class Order < ActiveRecord::Base
  class OrderRole < ActiveRecord::Base
    self.table_name = ('order_roles')
  end

  module InstanceMethods
    def complete_building
      # nothing just so mixin can use super
    end
  end
  include InstanceMethods
  include Uuid::Uuidable
  include Submission::AssetGroupBehaviour
  include Submission::ProjectValidation
  include Submission::RequestOptionsBehaviour
  include Submission::AccessionBehaviour
  include ModelExtensions::Order

  include Workflowed

  self.inheritance_column = 'sti_type'

  # Required at initial construction time ...
  belongs_to :study
  validates :study, presence: true, unless: :cross_study_allowed
  validate :study_is_active, on: :create

  belongs_to :project
  validates :project, presence: true, unless: :cross_project_allowed

  belongs_to :order_role, class_name: 'Order::OrderRole'
  delegate :role, to: :order_role, allow_nil: true

  belongs_to :product

  belongs_to :user
  validates_presence_of :user

  belongs_to :workflow, class_name: 'Submission::Workflow'
  validates_presence_of :workflow

  has_many :requests, inverse_of: :order

  belongs_to :submission, inverse_of: :orders
  scope :include_for_study_view, -> { includes(:submission) }
  # validates_presence_of :submission

  before_destroy :is_building_submission?
  after_destroy :on_delete_destroy_submission

  scope :containing_samples, ->(samples) { joins(assets: :samples).where(samples: { id: samples }) }

  def is_building_submission?
    submission.building?
  end

  def on_delete_destroy_submission
    if is_building_submission?
      # After destroying an order, if it is the last order on it's submission
      # destroy the submission too.
      orders = submission.orders
      submission.destroy unless orders.size > 1
      return true
    end
    false
  end

  serialize :request_types
  validates_presence_of :request_types

  serialize :item_options

  validate :assets_are_appropriate
  validate :no_consent_withdrawl

  class AssetTypeError < StandardError
  end

  def cross_study_allowed; false; end

  def cross_project_allowed; false; end

  def cross_compatible?; false; end

  def no_consent_withdrawl
    return true unless all_samples.any?(&:consent_withdrawn?)
    withdrawn_samples = all_samples.select(&:consent_withdrawn?).map(&:friendly_name)
    errors.add(:samples, "in this submission have had patient consent withdrawn: #{withdrawn_samples.to_sentence}")
    false
  end
  private :no_consent_withdrawl

  def assets_are_appropriate
    all_assets.each do |asset|
      errors.add(:asset, "'#{asset.name}' is a #{asset.sti_type} which is not suitable for #{first_request_type.name} requests") unless is_asset_applicable_to_type?(first_request_type, asset)
    end
    return true if errors.empty?
    false
  end
  private :assets_are_appropriate

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
    if assets.empty? && asset_group.present?
      pull_assets_from_asset_group
    end
    assets
  end

  scope :for_studies, ->(*args) { where(study_id: args) }

  self.per_page = 500
  scope :including_associations_for_json, -> {
    includes([
      :uuid_object,
      { assets: [:uuid_object] },
      { project: :uuid_object },
      { study: :uuid_object },
      :user
    ])
  }

  def self.render_class
    Api::OrderIO
  end

  def url_name
    'order'
  end
  alias_method(:json_root, :url_name)

  def asset_uuids
    assets.select { |asset| asset.present? }.map(&:uuid) if assets
  end

  # TODO[xxx]: I don't like the name but this should disappear once the UI has been fixed
  def self.prepare!(options)
    constructor = options.delete(:template) || self
    constructor.create_order!(options.merge(assets: options.fetch(:assets, [])))
  end

  class << self
    alias_method :create_order!, :create!
  end

  # only needed to note
  def self.build!(options)
    # call submission with appropriate Order subclass
    Submission.build!({ template: self }.merge(options))
  end

  def self.extended(_base)
    class_eval do
      def self.build!(*args)
        Order::build!(*args)
      end
    end
  end

  def multiplexed?
    RequestType.find(request_types).any?(&:for_multiplexing?)
  end

  def is_asset_applicable_to_type?(request_type, asset)
    request_type.asset_type == asset.asset_type_for_request_types.name
  end
  private :is_asset_applicable_to_type?

  delegate :left_building_state?, to: :submission, allow_nil: true

  def create_request_of_type!(request_type, attributes = {})
    em = request_type.extract_metadata_from_hash(request_options)
    request_type.create!(attributes) do |request|
      request.submission_id               = submission_id
      request.workflow                    = workflow
      request.study                       = study
      request.initial_project             = project
      request.user                        = user
      request.request_metadata_attributes = em
      request.state                       = initial_request_state(request_type)
      request.order                       = self

      if request.asset.present?
        raise AssetTypeError, 'Asset type does not match that expected by request type.' unless is_asset_applicable_to_type?(request_type, request.asset)
      end
    end
  end

  def duplicate(&block)
    create_parameters = template_parameters
    new_order = Order.create(create_parameters.merge(study: study, workflow: workflow,
                                                     user: user, assets: assets, state: state,
                                                     request_types: request_types,
                                                     request_options: request_options,
                                                     comments: comments,
                                                     project_id: project_id), &block)
    new_order.save
    new_order
  end

  def duplicates_within(timespan)
    matching_orders = Order.containing_samples(all_samples).where(template_name: template_name).includes(:submission, assets: :samples).where('orders.id != ?', id).where('orders.created_at > ?', DateTime.current - timespan)
    return false if matching_orders.empty?
    matching_samples = matching_orders.map(&:samples).flatten & all_samples
    matching_submissions = matching_orders.map(&:submission).uniq
    yield matching_samples, matching_orders, matching_submissions if block_given?
    true
  end

  #  attributes which are not saved for a submission but can be pre-set via SubmissionTemplate
  # return a list of request_types lists  (a sequence of choices) to display in the new view
  attr_writer :request_type_ids_list

  def request_type_ids_list; @request_type_ids_list ||= [[]]; end

  attr_accessor :info_differential # aggrement text to display when creating a new submission
  attr_accessor :customize_partial # the name of a partial to render.
  DefaultAssetInputMethods = ['select an asset group']
  # DefaultAssetInputMethods = ["select an asset group", "enter a list of asset ids", "enter a list of asset names", "enter a list of sample names"]
  attr_writer :asset_input_methods
  def asset_input_methods; @asset_input_methods ||= DefaultAssetInputMethods; end

  # return a hash with the values needed to be saved as a template
  # beware nil values are filtered to not overwride default value set in the initializer
  # (in case these default value are added after a template has been save)
  # So don't forget to filter again if you override this method.
  def template_parameters
    {
      request_options: request_options,
      request_types: request_types,
      comments: comments,
      request_type_ids_list: request_type_ids_list,
      workflow_id: workflow.id,
      info_differential: info_differential,
      customize_partial: customize_partial,
      asset_input_methods: asset_input_methods != DefaultAssetInputMethods ? asset_input_methods : nil
    }.reject { |_k, v| v.nil? }
  end

  def request_types_list
    request_type_ids_list.map { |ids| RequestType.find(ids) }
  end

  def first_request_type
    RequestType.find(request_types.first)
  end

  def filter_asset_groups(asset_groups)
    asset_groups
  end

  class CompositeAttribute
    attr_reader :display_name, :key, :default, :options
    def initialize(key)
      @key = key
    end

    def add(attribute, metadata)
      @display_name ||= attribute.display_name
      @key            = attribute.assignable_attribute_name
      @default      ||= attribute.find_default(nil, metadata)
      @kind           = attribute.kind if @kind.nil? || attribute.required?
      if attribute.selection?
        new_options   = attribute.selection_options(metadata)
        @options    ||= new_options if selection?
        @options     &= new_options
      end
    end

    def kind
      @kind || FieldInfo::TEXT
    end

    def selection?
      kind == FieldInfo::SELECTION
    end

    def to_field_infos
      values = {
        display_name: display_name,
        key: key,
        default_value: default,
        kind: kind
      }
      values.update(selection: options) if selection?
      FieldInfo.new(values)
    end
  end

  def request_attributes
    attributes = ActiveSupport::OrderedHash.new { |hash, value| hash[value] = CompositeAttribute.new(value) }
    request_types_list.flatten.each do |request_type|
      mocked = mock_metadata_for(request_type)
      request_type.request_class::Metadata.attribute_details.each do |att|
        attributes[att.name].add(att, mocked)
      end
      request_type.request_class::Metadata.association_details.each do |att|
        attributes[att.name].add(att, nil)
      end
    end

    attributes.values
  end

  def mock_metadata_for(request_type)
    # We have to create a mocked Metadata to point back at the appropriate request class, as request options
    # are no longer hardcoded in RequestClasses. This is a bit messy, but the tendrils of the old system went
    # deep. In hindsight it would probably have been easier to either:
    # a) Start from scratch
    # b) Not bother
    mock_request = request_type.request_class.new(request_type: request_type)
    request_type.request_class::Metadata.new(request: mock_request, owner: mock_request)
  end

  # Return the list of input fields to edit when creating a new submission
  # Unless you are doing something fancy, fall back on the defaults
  def input_field_infos
    return @input_field_infos if @input_field_infos
    @cache_calc ||= compute_input_field_infos
  end

  # we don't call it input_field_infos= because it has a slightly different meanings
  # if input_field_infos is computed it override the computation
  # this is meant do be used only when creating submission template
  def set_input_field_infos(infos)
    @input_field_infos = infos
  end

  def initial_request_state(request_type)
    (request_options || {}).fetch(:initial_state, {}).fetch(request_type.id, request_type.initial_state).to_s
  end
  private :initial_request_state

  def next_request_type_id(request_type_id)
    request_type_ids = request_types.map(&:to_i)
    request_type_ids[request_type_ids.index(request_type_id) + 1]
  end

  def compute_input_field_infos
    request_attributes.uniq.map do |combined|
      combined.to_field_infos
    end
  end
  protected :compute_input_field_infos

  # Are we still able to modify this instance?
  def building?
    submission.nil?
  end

  # Returns true if this is an order for sequencing
  def is_a_sequencing_order?
    [
     PacBioSequencingRequest,
     SequencingRequest,
     *SequencingRequest.descendants
    ].include?(RequestType.find(request_types.last).request_class)
  end

  def collect_gigabases_expected?
    input_field_infos.any? { |k| k.key == :gigabases_expected }
  end

  def add_comment(comment_str, user)
    update_attribute(:comments, [comments, comment_str].compact.join('; '))
    save!

    submission.requests.where_is_not_a?(TransferRequest).for_order_including_submission_based_requests(self).map do |request|
      request.add_comment(comment_str, user)
    end
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
    if study.present? && !study.active?
      errors.add(:study, 'is not active')
    end
  end
end
