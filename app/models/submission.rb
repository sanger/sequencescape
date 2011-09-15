class Submission < ActiveRecord::Base
  include Uuid::Uuidable
  extend  Submission::StateMachine
  include Submission::DelayedJobBehaviour
  #include ModelExtensions::Submission

  include DelayedJobEx



  # Created during the lifetime ...
  has_many :requests
  has_many :items, :through => :requests

  has_one :order
  def orders
    [order]
  end
  
  cattr_reader :per_page
  @@per_page = 500
  named_scope :including_associations_for_json, { :include => [:uuid_object, {:assets => [:uuid_object] }, { :project => :uuid_object }, { :study => :uuid_object }, :user] }

  # Before destroying this instance we should cancel all of the requests it has made
  before_destroy :cancel_all_requests_on_destruction

  def cancel_all_requests_on_destruction
    requests.all.each do |request|
      request.cancel!  # Cancel first to prevent event doing something stupid
      request.events.create!(:message => "Submission #{self.id} as destroyed")
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
  
  # TODO[xxx]: I don't like the name but this should disappear once the UI has been fixed
  def self.prepare!(options)
    constructor = options.delete(:template) || self
    constructor.create!(options.merge(:assets => options.fetch(:assets, [])))
  end

  def self.build!(options)
    ActiveRecord::Base.transaction do
      order = self.prepare!(options)
      order.submission.built!
      order.submission
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
      orders.each(&:build_request_graph!)
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

  def create_request_of_type!(request_type, attributes = {}, &block)
    request_type.create!(attributes) do |request|
      request.workflow                    = workflow
      request.project                     = project
      request.study                       = study
      request.user                        = user
      request.submission_id               = id
      request.request_metadata_attributes = request_type.extract_metadata_from_hash(request_options)
      request.state                       = initial_request_state(request_type)

      if request.asset.present?
        # TODO: This should really be an exception but not sure of the side-effects at the moment
        request.asset  = nil unless is_asset_applicable_to_type?(request_type, request.asset)
      end
    end
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
 validate :check_orders_are_compatible

 #Order needs to have the 'structure'
 def check_orders_are_compatible()
   orders.map(&:request_types).uniq.size <= 1
 end

 private :check_orders_are_compatible

  #for the moment we consider that request types should be the same for all order
  #so we can take the first one
  def request_type_ids
    return [] unless orders.present?
    orders.first.request_types.map(&:to_i)
  end


  def next_request_type_id(request_type_id)
    request_type_ids[request_type_ids.index(request_type_id)+1]  if request_type_ids.present?
  end

  def next_requests(request)
    return request.target_asset.requests if request.target_asset

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

end

class Array
  def intersperse(separator)
    (inject([]) { |a,v|  a+[v,separator] })[0...-1]
  end
end

