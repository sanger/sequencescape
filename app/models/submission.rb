# frozen_string_literal: true

# A Submission collects multiple Orders together, to define a body of work.
# In the case of non-multiplexed requests the submission is largely redundant,
# but for multiplexed requests it usually helps define which assets will get
# pooled together at multiplexing. There are two Order subclasses which are important
# when it comes to submissions:
# LinearSubmission => Most orders fall in this category. If the submission is multiplexed
#                     results in a single pool for the whole submissions.
# FlexibleSubmission => Allows request types to specify their own pooling rules, which are
#                       used to define pools at the submission level.
# While orders are mostly in charge of building their own requests, Submissions trigger this
# behaviour, and handle multiplexing between orders.
# JG: We may be able to consider relaxing the restrictions in check_orders_compatible? to
# allow us to have mixed submissions. This would avoid the need for complicating the submission
# builders further, and would give finer grained control of the way orders were processed.
# Essentially when it game to stuff like G&T you'd have two separate orders, and then the submission
# would determine they were pooled together. This would mean a slight increase in bulk-submission complexity
# (Each sample would be listed twice) but a massive increase in flexibility, while allowing up to
# defer submission changes until flexible pooling.
class Submission < ApplicationRecord
  include Uuid::Uuidable
  extend  Submission::StateMachine
  include Submission::DelayedJobBehaviour
  include ModelExtensions::Submission
  # TODO[mb14] check if really needed. We use them in project_test
  include Request::Statistics::DeprecatedMethods
  include Submission::Priorities

  PER_ORDER_REQUEST_OPTIONS = ['pre_capture_plex_level', 'gigabases_expected']

  self.per_page = 500

  belongs_to :user, required: true

  # Created during the lifetime ...
  # Once a submission has requests we REALLY shouldn't be destroying it.
  has_many :requests, inverse_of: :submission, dependent: :restrict_with_exception
  # Items are a legacy item that used to represent libraries which had yet to be made.
  # JG: I don't think we have any behaviour that depends on them. They can probably be removed.
  has_many :items, through: :requests
  has_many :events, through: :requests
  # Orders are the main submission workhorses, and do most the heavy lifting. They group together
  # assets, under a study and project, and collect together the request types which will be built,
  # and the request options.
  # Currently submissions check that all their orders have the same request types, and check that
  # #check_orders_compatible? but in practice we probably only NEED to ensure that sequencing request
  # types / read_lengths match.
  # Submissions with orders cannot be destroyed
  has_many :orders, inverse_of: :submission, dependent: :restrict_with_error
  has_many :studies, through: :orders
  # JG: Comments are a bit broken, but not sure how best to fix them. Orders set them on request,
  # but essentially this just sets the same comment on each request. And then we also have comments on
  # asset, but then plate also want to show the request comments. Its probably a case of simplifying things
  # and JUST allowing comments on submissions
  has_many :comments_from_requests, through: :requests, source: :comments

  # Required at initial construction time ...
  validate :validate_orders_are_compatible, if: :building?

  # We gate submission destruction. Should probably just prevent this.
  before_destroy :prevent_destruction_unless_building?

  accepts_nested_attributes_for :orders, update_only: true
  broadcast_via_warren

  # Used in the v1 API
  scope :including_associations_for_json, -> {
    includes([
      :uuid_object,
      { orders: [
        { project: :uuid_object },
        { assets: :uuid_object },
        { study: :uuid_object },
        :user
      ] }
    ])
  }

  scope :building, -> { where(state: 'building') }
  scope :pending,  -> { where(state: 'pending') }
  scope :ready,    -> { where(state: 'ready') }

  scope :latest_first, -> { order('id DESC') }

  scope :for_search_query, ->(query) { where(name: query) }

  # The class used to render warehouse messages
  def self.render_class
    Api::SubmissionIO
  end

  # Once submissions progress beyond building, destruction is a risky action and should be prevented.
  def prevent_destruction_unless_building?
    return if building?
    errors.add(:base, "can only be destroyed when in the 'building' stage. Later submissions should be cancelled.")
    trhow :abort
  end

  # As mentioned above, comments are broken. Not quite sure why we're overriding it here
  def comments
    orders.pluck(:comments).compact
  end

  # Adds the given comment to all requests in the submission
  # @param description [String] The comment to add to the submission
  # @param user [User] The user making the comment
  #
  # @return [Void]
  def add_comment(description, user)
    requests.each do |request|
      request.add_comment(description, user)
    end
  end

  def requests_cancellable?
    requests.all?(&:cancellable?)
  end

  def json_root
    'submission'
  end

  def subject_type
    'submission'
  end
  alias_attribute :friendly_name, :name

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

  # returns an array of samples, that potentially can not be included in submission
  def not_ready_samples
    @not_ready_samples ||= orders.map(&:not_ready_samples).flatten
  end

  def not_ready_samples_names
    @not_ready_samples_names ||= not_ready_samples.map(&:name).join(', ')
  end

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
    all_requests = request_cache_for(request.request_type_id, next_request_type_id).to_a
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
      divergence_ratio = divergence_ratio_cache_for(next_request_type_id)
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
    super.presence || "##{id} #{study_names.truncate(128)}"
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

  private

  # When passing libraries we may end up iterating over requests in a submission
  # We should have the same submission instance, so just cache the query result here.
  def request_cache_for(*request_type_ids)
    request_cache[request_type_ids]
  end

  # Divergence ratios are calculated from orders. we cache them per request type
  # A divergence ratio is the number of downstream requests made per upstream
  # request.
  def divergence_ratio_cache_for(next_request_type_id)
    divergence_ratio_cache[next_request_type_id]
  end

  def request_cache
    @request_cache ||= Hash.new do |cache, ids|
      cache[ids] = requests.with_request_type_id(ids)
                           .includes(:asset, :billing_product)
                           .order(id: :asc)
    end
  end

  def divergence_ratio_cache
    @divergence_ratio_cache ||= Hash.new do |cache, request_type_id|
      # If requests aren't multiplexed, then they may be batched separately, and we'll have issues
      # if downstream changes affect the ratio. We can use the multiplier on order however, as we
      # don't need to worry about divergence ratios f < 1
      # Determine the number of requests that should come next from the multipliers in the orders.
      # NOTE: This will only work whilst you order the same number of requests.
      multipliers = orders.reduce(Set.new) { |set, order| set << (order.request_options.dig(:multiplier, request_type_id.to_s) || 1).to_i }
      raise RuntimeError, "Mismatched multiplier information for submission #{id}" unless multipliers.one?
      # Now we can take the group of requests from next_possible_requests that tie up.
      cache[request_type_id] = multipliers.first
    end
  end

  def cancel_all_requests
    ActiveRecord::Base.transaction do
      requests.each(&:submission_cancelled!)
    end
  end

  # Order needs to have the 'structure'
  def validate_orders_are_compatible
    return true if orders.size < 2
    # check every order against the first one
    first_order = orders.first
    orders[1..-1].each { |o| check_orders_compatible?(o, first_order) }
    return false if errors.count > 0
  end
end
