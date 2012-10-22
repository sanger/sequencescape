class PipelinesRequestType < ActiveRecord::Base
  belongs_to :pipeline
  belongs_to :request_type
end

class Pipeline < ActiveRecord::Base
  include ::ModelExtensions::Pipeline

  has_many :batches do
    def build(attributes = nil)
      attributes ||= {}
      attributes[:item_limit] = proxy_owner.workflow.item_limit
      super(attributes)
    end
  end

  has_one :workflow, :class_name => "LabInterface::Workflow", :foreign_key => :pipeline_id
  delegate :item_limit, :has_batch_limit?, :to => :workflow
  validates_presence_of :workflow

  has_many :controls
  has_many :pipeline_request_information_types

  has_many :request_information_types, :through => :pipeline_request_information_types
  has_many :tasks, :through => :workflows
  belongs_to :location

  has_many :pipelines_request_types
  has_many :request_types, :through => :pipelines_request_types
  validate :has_request_types

  def has_request_types
    errors.add_to_base('A Pipeline must have at least one associcated RequestType') if self.request_types.blank?
  end
  private :has_request_types

  belongs_to :control_request_type, :class_name => 'RequestType'

  class RequestsProxy
    include Pipeline::RequestsInStorage

    def initialize(pipeline)
      @pipeline = pipeline
    end

    attr_reader :pipeline
    alias_method(:proxy_owner, :pipeline)
    private :proxy_owner

    def requests
      Request.for_pipeline(proxy_owner)
    end
    private :requests

    def respond_to?(name, include_private = false)
      super or requests.respond_to?(name, include_private)
    end

    def method_missing(name, *args, &block)
      requests.send(name, *args, &block)
    end
    protected :method_missing

    def inbox(show_held_requests = true, current_page = 1, action = nil)
      # Build a list of methods to invoke to build the correct request list
      actions = [ :unbatched ]
      actions.concat(proxy_owner.custom_inbox_actions)
      actions << ((proxy_owner.group_by_parent? or show_held_requests) ? :full_inbox : :pipeline_pending)
      actions << [ (proxy_owner.group_by_parent? ? :holder_located : :located), proxy_owner.location_id ]
      if action != :count
        actions << (proxy_owner.group_by_submission? ? :ordered_for_submission_grouped_inbox : :ordered_for_ungrouped_inbox)
        actions << :loaded_for_inbox_display
      end
      if action.present?
        actions << [ action ]
      elsif proxy_owner.paginate?
        actions << [ :paginate, { :per_page => 50, :page => current_page } ]
      end

      actions.inject(requests.include_request_metadata) { |context, action| context.send(*Array(action)) }
    end

    # Used by the Pipeline class to retrieve the list of requests that are coming into the pipeline.
    def inputs(show_held_requests = false)
      ready_in_storage.send(show_held_requests ? :full_inbox : :pipeline_pending)
    end
  end

  def requests
    RequestsProxy.new(self)
  end

  def request_types_including_controls
    [ control_request_type ] + request_types
  end

  def custom_inbox_actions
    []
  end

  belongs_to :next_pipeline,     :class_name => 'Pipeline'
  belongs_to :previous_pipeline, :class_name => 'Pipeline'

  named_scope :externally_managed, :conditions => { :externally_managed => true }
  named_scope :internally_managed, :conditions => { :externally_managed => false }
  named_scope :active,   :conditions => { :active => true }
  named_scope :inactive, :conditions => { :active => false }

  named_scope :for_request_type, lambda { |rt|
    {
      :joins => [ 'LEFT JOIN pipelines_request_types prt ON prt.pipeline_id = pipelines.id' ],
      :conditions => ['prt.request_type_id = ?', rt.id]
    }
  }



  self.inheritance_column = "sti_type"

  include SequencingQcPipeline
  include Uuid::Uuidable
  include Pipeline::InboxUngrouped
  include Pipeline::BatchValidation

  validates_presence_of :name
  validates_uniqueness_of :name, :on => :create, :message => "name already in use"

  INBOX_PARTIAL               = 'default_inbox'

  # Override this in subclasses if you want to display action links
  # for released batches
  ALWAYS_SHOW_RELEASE_ACTIONS = false

  def inbox_partial
    INBOX_PARTIAL
  end

  def display_next_pipeline?
    false
  end

  def requires_position?
    true
  end

  #This needs to be re-done a better way
  def qc?
    false
  end

  def library_creation?
    false
  end

  def genotyping?
    false
  end

  def sequencing?
    false
  end

  def need_picoset?
    false
  end

  # This is the old behaviour for every other pipeline.
  def detach_request_from_batch(batch, request)
    request.return_for_inbox!
    self.update_detached_request(batch, request)
    request.save!
  end

  def update_detached_request(batch, request)
    request.remove_unused_assets
  end

  def get_input_request_groups(show_held_requests=true)
    group_requests( inbox_scope_on(requests.inputs(show_held_requests).unbatched))
  end

  def inbox_scope_on(inbox_scope)
    custom_inbox_actions.inject(inbox_scope) { |context, action| context.send(action) }
  end
  private :inbox_scope_on

  def get_input_requests_for_group(group)
    #TODO add named_scope to load only the required requests
    key = hash_to_group_key(group)
    get_input_request_groups[key]
  end

  def hash_to_group_key(hash)
    if hash.is_a? Array
      group  = hash
    else
      group = []
      [:parent, :submission, :study].each do |s|
        if  self.send("group_by_#{s}?")
          group << hash[s]
        end
      end
    end
    group.map {|e| e.to_i}
  end

  def grouping_function(option = {})
    return lambda { |r| [r.container_id] } if option[:group_by_holder_only]

    lambda do |request|
      [].tap do |group_key|
        group_key << request.container_id  if group_by_parent?
        group_key << request.submission_id if group_by_submission?
      end
    end
  end
  private :grouping_function

  # to overwrite by subpipeline if needed
  def group_requests(requests, option={})
    requests.group_requests(:all, option).group_by(&grouping_function(option))
  end

  def group_key_to_hash(group)
    group  = group.dup # we don't want to modify the original group
    hash = {}
    [:parent, :submission, :study].each do |s|
      if  self.send("group_by_#{s}?")
        hash[s] = group.shift
      end
    end
    hash
  end

  def finish_batch(batch, user)
    batch.complete!(user)
  end
  deprecate :finish_batch

  def post_finish_batch(batch, user)
  end

  def completed_request_as_part_of_release_batch(request)
    if self.library_creation?
      unless request.failed?
        EventSender.send_pass_event(request.id, "", "Passed #{self.name}.", self.id)
        EventSender.send_request_update(request.id, "complete", "Completed pipeline: #{self.name}")
      end
    else
      EventSender.send_request_update(request.id, "complete", "Completed pipeline: #{self.name}")
    end
  end

  def release_batch(batch, user)
    batch.release!(user)
  end
  deprecate :release_batch

  def post_release_batch(batch, user)
  end

  def has_controls?
    self.controls.empty? ? false : true
  end

  def pulldown?
    false
  end

  def prints_a_worksheet_per_task?
    false
  end

  def grouping_parser(option = {})
    grouper_class = option[:group_by_holder_only] ? GrouperByHolderOnly : GrouperForPipeline
    grouper_class.new(self)
  end
  private :grouping_parser

  def selected_values_from(browser_options)
    browser_options.select { |_, v| v == '1' }
  end
  private :selected_values_from

  def extract_requests_from_input_params(params ={})
    if (request_ids = params["request"]).present?
      requests.inputs(true).find(selected_values_from(request_ids).map(&:first), :order => 'id ASC')
    elsif (selected_groups = params["request_group"]).present?
      grouping_parser.all(selected_values_from(selected_groups))
    else
      raise StandardError, "Unknown manner in which to extract requests!"
    end
  end

  def max_number_of_groups
    self[:max_number_of_groups] || 0
  end

  def valid_number_of_checked_request_groups?(params ={})
    return true if max_number_of_groups.zero?
    return true if (selected_groups = params['request_group']).blank?
    grouping_parser.count(selected_values_from(selected_groups)) <= max_number_of_groups
  end

  def all_requests_from_submissions_selected?(request_ids)
    true
  end

  def can_create_stock_assets?
    false
  end
end
