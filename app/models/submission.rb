# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

class Submission < ActiveRecord::Base
  include Uuid::Uuidable
  extend  Submission::StateMachine
  include Submission::DelayedJobBehaviour
  include ModelExtensions::Submission
  # TODO[mb14] check if really needed. We use them in project_test
  include Request::Statistics::DeprecatedMethods
  include Submission::Priorities

  belongs_to :user
  validates_presence_of :user

  # Created during the lifetime ...
  has_many :requests, inverse_of: :submission
  has_many :items, through: :requests
  has_many :events, through: :requests

  has_many :orders, inverse_of: :submission
  has_many :studies, through: :orders
  accepts_nested_attributes_for :orders, update_only: true

  has_many :comments_from_requests, through: :requests, source: :comments

  def comments
    orders.pluck(:comments).compact
  end

  def add_comment(description, user)
    requests.where_is_not_a?(TransferRequest).map do |request|
      request.add_comment(description, user)
    end
  end

  self.per_page = 500
  scope :including_associations_for_json, -> { includes([
    :uuid_object,
    { orders: [
      { project: :uuid_object },
      { assets: :uuid_object },
      { study: :uuid_object },
      :user] }
  ])}

  scope :building, -> { where(state: 'building') }
  scope :pending,  -> { where(state: 'pending') }
  scope :ready,    -> { where(state: 'ready') }

  scope :latest_first, -> { order('id DESC') }

  scope :for_search_query, ->(query, _with_includes) { where(name: query) }

  before_destroy :building?, :empty_of_orders?

  def empty_of_orders?
    orders.empty?
  end

  # Before destroying this instance we should cancel all of the requests it has made
  before_destroy :cancel_all_requests_on_destruction

  PER_ORDER_REQUEST_OPTIONS = ['pre_capture_plex_level', 'gigabases_expected']

  def cancel_all_requests_on_destruction
    ActiveRecord::Base.transaction do
      requests.find_each do |request|
        request.submission_cancelled! # Cancel first to prevent event doing something stupid
        request.events.create!(message: "Submission #{id} as destroyed")
      end
    end
  end
  private :cancel_all_requests_on_destruction

  def cancel_all_requests
    ActiveRecord::Base.transaction do
      requests.each(&:submission_cancelled!)
    end
  end
  private :cancel_all_requests

  def requests_cancellable?
    requests.all?(&:cancellable?)
  end

  def self.render_class
    Api::SubmissionIO
  end

  def url_name
    'submission'
  end
  alias_method(:json_root, :url_name)

  def subject_type
    'submission'
  end
  alias_attribute :friendly_name, :name

  def self.build!(options)
    submission_options = {}
    [:message, :priority].each do |option|
      value = options.delete(option)
      submission_options[option] = value if value
    end
    ActiveRecord::Base.transaction do
      order = Order.prepare!(options)
      order.create_submission({ user_id: order.user_id }.merge(submission_options))
      order.save! # doesn't save submission id otherwise
      study_name = order.study.try(:name)
      order.submission.update_attributes!(name: study_name) if study_name
      order.submission.reload
      order.submission.built!
      order.submission
    end
  end

  def safe_to_delete?
    ActiveSupport::Deprecation.warn 'Submission#safe_to_delete? may not recognise all states'
    if ready?
      return true
    else
      requests_in_progress = requests.select { |r| r.state != 'pending' || r.state != 'waiting' }
      requests_in_progress.empty? ? true : false
    end
  end

  def process_submission!
    # for now, we just delegate the requests creation to orders
    ActiveRecord::Base.transaction do
      multiplexing_assets = nil
      orders.each do |order|
        order.build_request_graph!(multiplexing_assets) { |a| multiplexing_assets ||= a }
      end

      PreCapturePool::Builder.new(self).build!

      errors.add(:requests, 'No requests have been created for this submission') if requests.empty?
      raise ActiveRecord::RecordInvalid, self if errors.present?
    end
  end
  alias_method(:create_requests, :process_submission!)

  def multiplexed?
    orders.any? { |o| RequestType.find(o.request_types).any?(&:for_multiplexing?) }
  end

  # Attempts to find the multiplexed asset (usually a multiplexed library tube) associated
  # with the submission. Useful when trying to pool requests into a pre-existing tube at the
  # end of the process.
  def multiplexed_asset
    # All our multiplexed requests end up in a single asset, so we don't care which one we find.
    requests.joins(:request_type).find_by(request_types: { for_multiplexing: true }).target_asset
  end

  def multiplex_started_passed
    multiplex_started_passed_result = false
    if multiplexed?
      requests = Request.where(submission_id: id)
      states = requests.map(&:state).uniq
      if (states.include?('started') || states.include?('passed'))
        multiplex_started_passed_result = true
      end
    end
    multiplex_started_passed_result
  end

  def each_submission_warning
    store = { samples: [], submissions: [] }
    orders.each do |order|
      order.duplicates_within(1.month) do |samples, _orders, submissions|
        store[:samples].concat(samples)
        store[:submissions].concat(submissions)
      end
    end
    yield store[:samples].uniq, store[:submissions].uniq unless store[:samples].empty?
  end

  # Required at initial construction time ...
  validate :validate_orders_are_compatible

  # Order needs to have the 'structure'
  def validate_orders_are_compatible
    return true if orders.size < 2
    # check every order against the first one
    first_order = orders.first
    orders[1..-1].each { |o| check_orders_compatible?(o, first_order) }
    return false if errors.count > 0
  end
  private :validate_orders_are_compatible

  # this method is part of the submission
  # not order, because it is submission
  # which decide if orders are compatible or not
  def check_orders_compatible?(a, b)
    errors.add(:request_types, 'are incompatible') if a.request_types != b.request_types
    errors.add(:request_options, 'are incompatible') unless request_options_compatible?(a, b)
    check_studies_compatible?(a.study, b.study)
  end

  def request_options_compatible?(a, b)
   a.request_options.reject { |k, _| PER_ORDER_REQUEST_OPTIONS.include?(k) } == b.request_options.reject { |k, _| PER_ORDER_REQUEST_OPTIONS.include?(k) }
  end

  def check_studies_compatible?(a, b)
    errors.add(:study, "Can't mix contaminated and non contaminated human DNA") unless a.study_metadata.contaminated_human_dna == b.study_metadata.contaminated_human_dna
    errors.add(:study, "Can't mix X and autosome removal with non-removal") unless a.study_metadata.remove_x_and_autosomes == b.study_metadata.remove_x_and_autosomes
  end

  # for the moment we consider that request types should be the same for all order
  # so we can take the first one
  def request_type_ids
    return [] unless orders.present?
    orders.first.request_types.map(&:to_i)
  end

  def find_next_request_type_id(request_type_id)
    request_type_ids[request_type_ids.index(request_type_id) + 1]  if request_type_ids.present?
  end

  def previous_request_type_id(request_type_id)
    request_type_ids[request_type_ids.index(request_type_id) - 1]  if request_type_ids.present?
  end

  def next_requests_to_connect(request, next_request_type_id = nil)
    if next_request_type_id.nil?
      next_request_type_id = find_next_request_type_id(request.request_type_id) or return []
    end
    all_requests = requests.with_request_type_id([request.request_type_id, next_request_type_id]).order(id: :asc)
    sibling_requests, next_possible_requests = all_requests.partition { |r| r.request_type_id == request.request_type_id }

    if request.request_type.for_multiplexing?
      # If we have no pooling behaviour specified, then we're pooling by submission.
      # We keep to the existing behaviour, to isolate risk
      return next_possible_requests if request.request_type.pooling_method.nil?
      # If we get here we've got custom pooling behaviour defined.
      index = request.request_type.pool_index_for_request(request)
      number_to_return = next_possible_requests.count / request.request_type.pool_count
      return next_possible_requests.slice(index * number_to_return, number_to_return)

    else
      # If requests aren't multiplexed, then they may be batched separately, and we'll have issues
      # if downstream changes affect the ratio. We can use the multiplier on order however, as we
      # don't need to worry about divergence ratios f < 1
      # Determine the number of requests that should come next from the multipliers in the orders.
      # NOTE: This will only work whilst you order the same number of requests.
      multipliers = orders.map { |o| (o.request_options[:multiplier].try(:[], next_request_type_id.to_s) || 1).to_i }.compact.uniq
      raise RuntimeError, "Mismatched multiplier information for submission #{id}" if multipliers.size != 1
      # Now we can take the group of requests from next_possible_requests that tie up.
      divergence_ratio = multipliers.first
      index = sibling_requests.map(&:id).index(request.id)
      next_possible_requests[index * divergence_ratio, [1, divergence_ratio].max]
    end
  end

  def next_requests(request)
    # We should never be receiving requests that are not part of our request graph.
    raise RuntimeError, "Request #{request.id} is not part of submission #{id}" unless request.submission_id == id

      # Pick out the siblings of the request, so we can work out where it is in the list, and all of
      # the requests in the subsequent request type, so that we can tie them up.  We order by ID
      # here so that the earliest requests, those created by the submission build, are always first;
      # any additional requests will have come from a sequencing batch being reset.
      next_request_type_id = find_next_request_type_id(request.request_type_id) or return []
      return request.target_asset.requests.where(submission_id: id, request_type_id: next_request_type_id) if request.target_asset.present?
      next_requests_to_connect(request, next_request_type_id)
  end

  def name
    given_name = super || study_names
    given_name.present? ? given_name : "##{id}"
  end

  def study_names
    # TODO: Should probably be re-factored, although we'll only fall back to the intensive code in the case of cross study re-requests
    orders.map { |o| o.study.try(:name) || o.assets.map { |a| a.aliquots.map { |al| al.study.try(:name) } } }.flatten.compact.sort.uniq.join('|')
  end

  def cross_project?
    multiplexed? && orders.map(&:project_id).uniq.size > 1
  end

  def cross_study?
    multiplexed? && orders.map(&:study_id).uniq.size > 1
  end
end
