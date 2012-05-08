class Submission < ActiveRecord::Base
  include Uuid::Uuidable
  extend  Submission::StateMachine
  include Submission::DelayedJobBehaviour
  include ModelExtensions::Submission
  #TODO[mb14] check if really needed. We use them in project_test
  include Request::Statistics::DeprecatedMethods


  include DelayedJobEx

  belongs_to :user
  validates_presence_of :user

  # Created during the lifetime ...
  has_many :requests
  has_many :items, :through => :requests

  has_many :orders, :inverse_of => :submission
  has_many :studies, :through => :orders
  accepts_nested_attributes_for :orders, :update_only => true

  def comments
    # has_many throug doesn't work. Comments is a column (string) of order
    # not an ActiveRecord
    orders.map(&:comments).flatten(1).compact
  end

  cattr_reader :per_page
  @@per_page = 500
  named_scope :including_associations_for_json, {
    :include => [
      :uuid_object,
      {:orders => [
         {:project => :uuid_object},
         {:assets => :uuid_object },
         {:study => :uuid_object },
         :user]}
  ]}

  named_scope :building, :conditions => { :state => "building" }
  named_scope :pending, :conditions => { :state => "pending" }
  named_scope :ready, :conditions => { :state => "ready" }

  # Before destroying this instance we should cancel all of the requests it has made
  before_destroy :cancel_all_requests_on_destruction

  def cancel_all_requests_on_destruction
    ActiveRecord::Base.transaction do
      requests.all.each do |request|
        request.cancel_before_started!  # Cancel first to prevent event doing something stupid
        request.events.create!(:message => "Submission #{self.id} as destroyed")
      end
    end
  end
  private :cancel_all_requests_on_destruction

  def self.render_class
    Api::SubmissionIO
  end

  def url_name
    "submission"
  end
  alias_method(:json_root, :url_name)

  def self.build!(options)
    submission_options = {}
    [:message].each do |option|
      value = options.delete(option)
      submission_options[option] = value if value
    end
    ActiveRecord::Base.transaction do
      order = Order.prepare!(options)
      order.create_submission({:user_id => order.user_id}.merge(submission_options)).built!
      order.save! #doesn't save submission id otherwise
      study_name = order.try(:study).name
      order.submission.update_attributes!(:name=>study_name) if study_name
      order.submission.reload
    end
  end
  # TODO[xxx]: ... to here really!

  def safe_to_delete?
    ActiveSupport::Deprecation.warn "Submission#safe_to_delete? may not recognise all states"
    unless self.ready?
      requests_in_progress = self.requests.select{|r| r.state != 'pending' || r.state != 'waiting'}
      requests_in_progress.empty? ? true : false
    else
      return true
    end
  end

  def process_submission!
    # for now, we just delegate the requests creation to orders
    ActiveRecord::Base.transaction do
      multiplexing_assets = nil
      orders.each do |order|
        order.build_request_graph!(multiplexing_assets) { |a| multiplexing_assets ||= a }
      end
    end
  end
  alias_method(:create_requests, :process_submission!)

  def multiplexed?
    orders.any? { |o| RequestType.find(o.request_types).any?(&:for_multiplexing?) }
  end


  def multiplex_started_passed
    multiplex_started_passed_result = false
    if self.multiplexed?
      requests = Request.find_all_by_submission_id(self.id)
      states = requests.map(&:state).uniq
      if ( states.include?("started") || states.include?("passed") )
        multiplex_started_passed_result = true
      end
    end
    return multiplex_started_passed_result
  end

  def duplicate(&block)
    raise "Not implemented yet"

    create_parameters = template_parameters
    new_submission = Submission.create(create_parameters.merge( :study => self.study,:workflow => self.workflow,
          :user => self.user, :assets => self.assets, :state => self.state,
          :request_types => self.request_types,
          :request_options => self.request_options,
          :comments => self.comments,
          :project_id => self.project_id), &block)
    new_submission.save
    return new_submission
  end












 #Required at initial construction time ...
 validate :validate_orders_are_compatible

 #Order needs to have the 'structure'
 def validate_orders_are_compatible()
    return true if orders.size < 2
    # check every order agains the first one
    first_order = orders.first
    orders[1..-1].each { |o| check_orders_compatible?(o,first_order) }
 end
 private :validate_orders_are_compatible

 # this method is part of the submission
  # not order, because it is submission
 # which decide if orders are compatible or not
 def check_orders_compatible?(a,b)
    errors.add(:request_types, "are incompatible") if a.request_types != b.request_types
    errors.add(:request_options, "are incompatible") if a.request_options != b.request_options
    errors.add(:item_options, "are incompatible") if a.item_options != b.item_options
    check_studies_compatible?(a.study, b.study)
    check_samples_compatible?(a,b)
 end

 def check_studies_compatible?(a,b)
    errors.add(:study, "Can't mix contaminated and non contaminated human DNA") unless a.study_metadata.contaminated_human_dna == b.study_metadata.contaminated_human_dna
 end

 def check_samples_compatible?(a,b)
    reference_genomes = [a, b].map(&:samples).flatten.uniq.group_by(&:sample_reference_genome).keys
    errors.add(:samples, "Can't mix reference genenome") if  reference_genomes.size > 1
 end

  #for the moment we consider that request types should be the same for all order
  #so we can take the first one
  def request_type_ids
    return [] unless orders.size >= 1
    orders.first.request_types.map(&:to_i)
  end


  def next_request_type_id(request_type_id)
    request_type_ids[request_type_ids.index(request_type_id)+1]  if request_type_ids.present?
  end

  def next_requests(request)
    # We should never be receiving requests that are not part of our request graph.
    raise RuntimeError, "Request #{request.id} is not part of submission #{id}" unless request.submission_id == self.id
    return request.target_asset.requests if request.target_asset.present?

    next_request_type_id = self.next_request_type_id(request.request_type_id)
    sibling_requests = requests.select { |r| r.request_type_id == request.request_type_id}
    next_possible_requests = requests.select { |r| r.request_type_id == next_request_type_id}

    #we need to find the position of the request within its sibling and use the same index
    #in the next_possible ones.

    [sibling_requests, next_possible_requests].map do |request_list|
      request_list.sort! { |a, b| a.id <=> b.id }
    end

    # The divergence_ratio should be equal to the multiplier if there is one and so the same for every requests
    # should work also for convergent a request (ration < 1.0))

    divergence_ratio = 1.0* next_possible_requests.size / sibling_requests.size
    index = sibling_requests.index(request)

    next_possible_requests[index*divergence_ratio,[ 1, divergence_ratio ].max]
  end

  def name
    name = attributes[:name] || orders.map {|o| o.try(:study).try(:name) }.compact.sort.uniq.join("|")
    name.present? ? name : "##{id}"
  end

end

class Array
  def intersperse(separator)
    (inject([]) { |a,v|  a+[v,separator] })[0...-1]
  end
end

