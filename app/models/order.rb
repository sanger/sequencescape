# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015,2016 Genome Research Ltd.

class Order < ApplicationRecord
  module InstanceMethods
    def complete_building
      # nothing just so mixin can use super
    end
  end
  AssetTypeError = Class.new(StandardError)
  DefaultAssetInputMethods = ['select an asset group']

  include InstanceMethods
  include Uuid::Uuidable
  include Submission::AssetGroupBehaviour
  include Submission::ProjectValidation
  include Submission::RequestOptionsBehaviour
  include Submission::AccessionBehaviour
  include ModelExtensions::Order

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

  self.inheritance_column = 'sti_type'
  self.per_page = 500

  #  attributes which are not saved for a submission but can be pre-set via SubmissionTemplate
  # return a list of request_types lists  (a sequence of choices) to display in the new view
  attr_writer :request_type_ids_list
  attr_accessor :info_differential # aggrement text to display when creating a new submission
  attr_accessor :customize_partial # the name of a partial to render.
  attr_writer :asset_input_methods

  # Required at initial construction time ...
  belongs_to :study, optional: true
  belongs_to :project, optional: true
  belongs_to :user, required: true
  belongs_to :product, optional: true
  belongs_to :order_role, optional: true
  belongs_to :submission, inverse_of: :orders
  # In the case of some cross study/project orders, such as resequencing of
  # mixed pools, there is no study/project on the order itself.
  # In some cases, such as viewing submission, it can be useful to display
  # the associated studies/projects
  has_many :source_asset_studies, ->() { distinct }, through: :assets, source: :studies
  has_many :source_asset_projects, ->() { distinct }, through: :assets, source: :projects
  has_many :requests, inverse_of: :order

  serialize :request_types
  serialize :item_options

  validates :study, presence: true, unless: :cross_study_allowed
  validates :project, presence: true, unless: :cross_project_allowed
  validates :request_types, presence: true

  validate :study_is_active, on: :create
  validate :assets_are_appropriate
  validate :no_consent_withdrawl

  # validates_presence_of :submission

  before_destroy :is_building_submission?
  after_destroy :on_delete_destroy_submission

  acts_as_authorizable
  broadcast_via_warren

  scope :include_for_study_view, -> { includes(:submission) }
  scope :containing_samples, ->(samples) { joins(assets: :samples).where(samples: { id: samples }) }
  scope :for_studies, ->(*args) { where(study_id: args) }

  scope :including_associations_for_json, -> {
    includes([
      :uuid_object,
      { assets: [:uuid_object] },
      { project: :uuid_object },
      { study: :uuid_object },
      :user
    ])
  }

  delegate :role, to: :order_role, allow_nil: true

  class << self
    alias_method :create_order!, :create!

    def render_class
      Api::OrderIO
    end

    # TODO[xxx]: I don't like the name but this should disappear once the UI has been fixed
    def prepare!(options)
      constructor = options.delete(:template) || self
      constructor.create_order!(options.merge(assets: options.fetch(:assets, [])))
    end

    # only needed to note
    def build!(options)
      # call submission with appropriate Order subclass
      Submission.build!({ template: self }.merge(options))
    end
  end

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

  def cross_study_allowed; false; end

  def cross_project_allowed; false; end

  def cross_compatible?; false; end

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

  def url_name
    'order'
  end
  alias_method(:json_root, :url_name)

  def asset_uuids
    assets.select { |asset| asset.present? }.map(&:uuid) if assets
  end

  def multiplexed?
    RequestType.find(request_types).any?(&:for_multiplexing?)
  end

  def create_request_of_type!(request_type, attributes = {})
    em = request_type.extract_metadata_from_hash(request_options)
    request_type.create!(attributes) do |request|
      request.submission_id               = submission_id
      request.study                       = study
      request.initial_project             = project
      request.user                        = user
      request.request_metadata_attributes = em
      request.state                       = initial_request_state(request_type)
      request.order                       = self

      if request.asset.present?
        raise AssetTypeError, 'Asset type does not match that expected by request type.' unless asset_applicable_to_type?(request_type, request.asset)
      end
    end
  end

  def duplicate(&block)
    create_parameters = template_parameters
    new_order = Order.create(create_parameters.merge(study: study,
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

  def request_type_ids_list; @request_type_ids_list ||= [[]]; end

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

  def request_attributes
    attributes = Hash.new { |hash, value| hash[value] = CompositeAttribute.new(value) }
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

  def next_request_type_id(request_type_id)
    request_type_ids = request_types.map(&:to_i)
    request_type_ids[request_type_ids.index(request_type_id) + 1]
  end

  # Are we still able to modify this instance?
  def building?
    submission.nil?
  end

  # Returns true if this is an order for sequencing
  def is_a_sequencing_order?
    RequestType.find(request_types).any? { |rt| rt.request_class.sequencing? }
  end

  def collect_gigabases_expected?
    input_field_infos.any? { |k| k.key == :gigabases_expected }
  end

  def add_comment(comment_str, user)
    update_attribute(:comments, [comments, comment_str].compact.join('; '))
    save!

    submission.requests.for_order_including_submission_based_requests(self).map do |request|
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

  # returns an array of samples, that potentially can not be included in submission
  def not_ready_samples
    all_samples.reject { |sample| sample.can_be_included_in_submission? }
  end

  protected

  # JG: Not entirely sure why this was flagged as protected, rather than private
  def compute_input_field_infos
    request_attributes.uniq.map do |combined|
      combined.to_field_infos
    end
  end

  private

  def asset_applicable_to_type?(request_type, asset)
    request_type.asset_type == asset.asset_type_for_request_types.name
  end

  def initial_request_state(request_type)
    (request_options || {}).fetch(:initial_state, {}).fetch(request_type.id, request_type.initial_state).to_s
  end

  def no_consent_withdrawl
    return true unless all_samples.any?(&:consent_withdrawn?)
    withdrawn_samples = all_samples.select(&:consent_withdrawn?).map(&:friendly_name)
    errors.add(:samples, "in this submission have had patient consent withdrawn: #{withdrawn_samples.to_sentence}")
    false
  end

  def assets_are_appropriate
    all_assets.each do |asset|
      errors.add(:asset, "'#{asset.name}' is a #{asset.sti_type} which is not suitable for #{first_request_type.name} requests") unless asset_applicable_to_type?(first_request_type, asset)
    end
    return true if errors.empty?
    false
  end
end
