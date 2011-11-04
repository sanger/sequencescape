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

  belongs_to :request_type
  validates_presence_of :request_type

  has_many :requests, :through => :request_type, :extend => Pipeline::RequestsInStorage do
    def inbox(show_held_requests = true, current_page = 1)
      # Build a list of methods to invoke to build the correct request list
      actions = [ :unbatched ]
      actions << ((proxy_owner.group_by_parent? or show_held_requests) ? :full_inbox : :pipeline_pending)
      actions << [ (proxy_owner.group_by_parent? ? :holder_located : :located), proxy_owner.location_id ]
      actions << (proxy_owner.group_by_submission? ? :ordered_for_submission_grouped_inbox : :ordered_for_ungrouped_inbox)
      actions << [ :paginate, { :per_page => 50, :page => current_page } ] if proxy_owner.paginate?

      actions.inject(self.include_request_metadata) { |context, action| context.send(*Array(action)) }
    end

    # Used by the Pipeline class to retrieve the list of requests that are coming into the pipeline.
    def inputs(show_held_requests = false)
      ready_in_storage.send(show_held_requests ? :full_inbox : :pipeline_pending)
    end
  end

  belongs_to :next_pipeline,     :class_name => 'Pipeline'
  belongs_to :previous_pipeline, :class_name => 'Pipeline'

  named_scope :externally_managed, :conditions => { :externally_managed => true }
  named_scope :internally_managed, :conditions => { :externally_managed => false }
  named_scope :active,   :conditions => { :active => true }
  named_scope :inactive, :conditions => { :active => false }
  
  acts_as_audited :on => [:destroy, :update]

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
    request.detach!
    self.update_detached_request(batch, request)
    request.save!
  end

  def update_detached_request(batch, request)
    request.remove_unused_assets
  end

  def get_input_request_groups(show_held_requests=true)
    group_requests(requests.inputs(show_held_requests))
  end
  
  # to overwrite by subpipeline if needed
  def group_requests(requests, option={})
    ids = requests.map { |r| r.id }
    if option[:by_target]
      holder_map = Request.get_target_holder_asset_id_map ids
    else
      holder_map = Request.get_holder_asset_id_map ids
    end

    if option[:group_by_holder_only]
      requests.group_by { |r|  [holder_map[r.id]] }
    else
      requests.group_by { |r|  request_to_group_key(r, holder_map) }
    end
  end

  def request_to_group_key(request, holder_map)
    [].tap do |group_key|
      group_key << holder_map[request.id] if group_by_parent?
      group_key << request.submission_id  if group_by_submission?
      group_key << request.study_id       if group_by_study?
    end
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

  def get_input_requests_for_group(group)
    #TODO add named_scope to load only the required requests
    key = hash_to_group_key(group)
    get_input_request_groups[key]
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


  def extract_request_ids_from_input_params(params ={})
    request_ids = []
    if params["request"]
      request_ids = params["request"].map {|a| a[1] == "1" ? a[0] : nil }.select {|a| !a.nil? }.collect{|x| x.to_i }.sort
    elsif params["request_group"]
      request_groups = params["request_group"]
      # we load all the request group and then filter them. Can be optimized by fitering when loading
      input_request_groups = self.get_input_request_groups(true)

      input_request_groups.each do |group|
        key, requests = group
        group_key = key.join ", "
        request_ids += requests.map { |r| r.id } if request_groups[group_key] == "1"
      end
    end

    request_ids
  end
  
  def valid_number_of_checked_request_groups?(params ={})
    return true if self.max_number_of_groups.nil? ||  self.max_number_of_groups == 0
    
    number_of_groups = 0
    if params[:request_group]
      request_groups = params[:request_group]
      input_request_groups = self.get_input_request_groups(true)

      input_request_groups.each do |group|
        key, requests = group
        group_key = key.join ", "
        number_of_groups += 1 if request_groups[group_key] == "1"
      end
    end
    
    return false if number_of_groups > self.max_number_of_groups

    true
  end
  
  def all_requests_from_submissions_selected?(request_ids)
    true
  end

  def can_create_stock_assets?
    false
  end
end
