class Request < ActiveRecord::Base
  include ModelExtensions::Request
  include Aliquot::DeprecatedBehaviours::Request

  include Api::RequestIO::Extensions
  cattr_reader :per_page
  @@per_page = 500

  include Uuid::Uuidable
  include AASM
  include AasmExtensions
  include Commentable
  include Proxyable
  include StandardNamedScopes
  include Request::Statemachine
  extend Request::Statistics

  extend EventfulRecord
  has_many_events
  has_many_lab_events

  self.inheritance_column = "sti_type"

  def self.delegate_validator
    DelegateValidation::AlwaysValidValidator
  end

  belongs_to :pipeline
  belongs_to :item

  has_many :failures, :as => :failable
  has_many :batch_requests
  has_many :batches, :through => :batch_requests
  has_many :billing_events

  has_many :request_quotas
  has_many :quotas, :through => :request_quotas

  belongs_to :request_type
  belongs_to :workflow, :class_name => "Submission::Workflow"

  belongs_to :user

  belongs_to :submission

  #temporary hack
  # project is read only so we can set it everywhere
  # but it will be only used in specific and controlled place
  belongs_to :initial_project, :class_name => "Project"

  def project_id=(project_id)
    raise RuntimeError "Initial project already set" if initial_project_id
    self.initial_project_id = project_id

    
    #use quota if neeed
    #we can't use quota now, because if we are building the request, the request type might
    # haven't been assigned yet. 
    # We use in instance variable instead and book the request in a before_save callback
    # 
    @orders_to_book = self.initial_project.orders
    book_quotas unless new_record?
    #self.initial_project.orders.each { |o| o.use_quota!(self, o.assets.present?) }
  end


  def book_quotas
    return unless @orders_to_book
    # if assets are empty the order hasn't booked anything, so there is no need to unbook quota
    # Should happen in real life but might in test
    @orders_to_book.each { |o| o.use_quota!(self, o.assets.present?) }
    @orders_to_book = nil
  end
  private :book_quotas
  after_create :book_quotas

  def project=(project)
    return unless project
    self.project_id=project.id
  end

  #same as project with study
  belongs_to :initial_study, :class_name => "Study"

  def study_id=(study_id)
    raise RuntimeError "Initial study already set" if initial_study_id
    self.initial_study_id = study_id
  end

  def study=(study)
    return unless study
    self.study_id=study.id
  end


  #  validates_presence_of :study, :request_type#TODO, :submission

  named_scope :between, lambda { |source,target| { :conditions => { :asset_id => source.id, :target_asset_id => target.id } } }

  # new version of combinable named_scope
  named_scope :for_state, lambda { |state| { :conditions => { :state => state } } }

  named_scope :completed, :conditions => {:state => COMPLETED_STATE =["passed", "failed"]}
  named_scope :passed, :conditions => {:state => "passed"}
  named_scope :failed, :conditions => {:state => "failed"}
  named_scope :pipeline_pending, :conditions => {:state => "pending"} #  we don't want the blocked one here
  named_scope :pending, :conditions => {:state => ["pending", "blocked"]} # block is a kind of substate of pending

  named_scope :started, :conditions => {:state => "started"}
  named_scope :cancelled, :conditions => {:state => "cancelled"}
  named_scope :aborted, :conditions => {:state => "aborted"}

  named_scope :open, :conditions => {:state => OPENED_STATE=["pending", "blocked", "started"]}
  named_scope :closed, :conditions => {:state => ["passed", "failed", "cancelled", "aborted"]}
  named_scope :quota_counted, :conditions => {:state => QUOTA_COUNTED=["passed", "pending", "blocked", "started"]}
  named_scope :quota_exempted, :conditions => {:state => QUOTA_EXEMPTED=["failed", "cancelled", "aborted"]}
  named_scope :hold, :conditions => {:state => "hold"}

  # TODO: Really need to be consistent in who our named scopes behave
  named_scope :request_type, lambda { |request_type|
    id =
      case 
      when request_type.nil? then nil   # TODO: Are the pipelines with nil request_type_id really nil?
      when request_type.is_a?(Fixnum), request_type.is_a?(String) then request_type
      else request_type.id
      end
    {:conditions => { :request_type_id => id} }
  }

  named_scope :where_is_a?,     lambda { |clazz| { :conditions => [ 'sti_type IN (?)',     [ clazz, *Class.subclasses_of(clazz) ].map(&:name) ] } }
  named_scope :where_is_not_a?, lambda { |clazz| { :conditions => [ 'sti_type NOT IN (?)', [ clazz, *Class.subclasses_of(clazz) ].map(&:name) ] } }
  named_scope :where_has_a_submission, { :conditions => 'submission_id IS NOT NULL' }

  named_scope :full_inbox, :conditions => {:state => ["pending","hold"]}

  named_scope :with_asset, :conditions =>  'asset_id is not null'
  named_scope :with_target, :conditions =>  'target_asset_id is not null and (target_asset_id <> asset_id)'
  named_scope :join_asset, :joins => [ :asset ]

  #Asset are Locatable (or at least some of them)
  belongs_to :location_association, :primary_key => :locatable_id, :foreign_key => :asset_id
  named_scope :located, lambda {|location_id| { :joins => :location_association, :conditions =>  ['location_associations.location_id = ?', location_id ] } }

  #Use container location
  named_scope :holder_located, lambda { |location_id|
    {
      :joins => ["INNER JOIN container_associations ON content_id = asset_id", "INNER JOIN location_associations ON location_associations.locatable_id = container_id"],
      :conditions => ['location_associations.location_id = ?', location_id ] 
    }
  }
  named_scope :without_asset, :conditions =>  'asset_id is null'
  named_scope :without_target, :conditions =>  'target_asset_id is null'
  named_scope :ordered, :order => ["id ASC"]
  named_scope :full_inbox, :conditions => {:state => ["pending","hold"]}
  named_scope :hold, :conditions => {:state => "hold"}

  named_scope :ordered_for_ungrouped_inbox, :order => 'id DESC'
  named_scope :ordered_for_submission_grouped_inbox, :order => 'submission_id DESC, id ASC'

  named_scope :for_asset_id, lambda { |id| { :conditions => { :asset_id => id } } }
  named_scope :for_study_ids, lambda { |ids|
    {
      :joins =>  %Q(
      INNER JOIN (assets AS a, aliquots AS al)
       ON (requests.asset_id = a.id
           AND  al.receptacle_id = a.id 
           AND al.study_id IN (#{ids.join(", ")}))
             ),
       :group => "requests.id"
    }
  } do
    #fix a bug in rail, the group clause if removed
    #therefor we need to the DISTINCT parameter
    def count
      super('requests.id',:distinct =>true)
    end
  end

  def self.for_study_id (study_id)
    for_study_ids([study_id])
  end
  def self.for_study(study)
    Request.for_study_id(study.id)
  end
  def self.for_studies(studies)
    for_study_ids(studies.map(&:id))
  end




  delegate :study, :study_id, :to => :asset, :allow_nil => true

  named_scope :for_workflow, lambda { |workflow| { :joins => :workflow, :conditions => { :workflow => { :key => workflow } } } }
  named_scope :for_request_types, lambda { |types| { :joins => :request_type, :conditions => { :request_types => { :key => types } } } }
  
  named_scope :for_search_query, lambda { |query|
    { :conditions => [ 'id=?', query ] }
  }

  named_scope :find_all_target_asset, lambda { |target_asset_id| { :conditions => [ 'target_asset_id = ?', "#{target_asset_id}" ] } }
  named_scope :for_studies, lambda { |*studies| { :conditions => { :initial_study_id => studies.map(&:id) } } }

  #------
  #TODO: use eager loading association
  def self.get_holder_asset_id_map(request_ids)
    # the alias request_id to  id is a trick to store request_id in a existing attribute of Asset.
    rows = ContainerAssociation.find(:all, :joins => "INNER JOIN requests ON content_id = asset_id" , :select => "requests.id id, container_id", :conditions => ["requests.id IN  (?)", request_ids])
    # now , we transform the result into a Hash : request_ids -> holder id
    h = {}
    rows.each do |row|
      h[row.id] = row.container_id
    end

    return h
  end

  def self.get_target_holder_asset_id_map(request_ids)
    # the alias request_id to  id is a trick to store request_id in a existing attribute of Asset.
    rows = ContainerAssociation.find(:all, :joins => "INNER JOIN requests ON content_id = target_asset_id" , :select => "requests.id id, container_id", :conditions => ["requests.id IN  (?)", request_ids])
    # now , we transform the result into a Hash : request_ids -> holder id
    h = {}
    rows.each do |row|
      h[row.id] = row.container_id
    end

    return h
  end

  # The options that are required for creation.  In other words, the truly required options that must
  # be filled in and cannot be changed if the asset we're creating is used downstream.  For example,
  # a library tube definitely has to have fragment_size_required_from, fragment_size_required_to and
  # library_type and these cannot be changed once the library has been made.
  #
  #--
  # Side note: really this information should be stored on the asset itself, which suggests there is
  # a discrepancy in our model somewhere.
  #++
  def request_options_for_creation
    {}
  end

  def recycle_from_batch!(batch)
    self.detach!
    self.batches.delete(batch)
    #self.detach
    #self.batches -= [ batch ]
  end

  def study_item
    Item.find(:first, :conditions => {:id => self.item_id})
  end

  def finished?
    self.passed? || self.failed?
  end

  def get_value(request_information_type)
    return '' unless self.request_metadata.respond_to?(request_information_type.key.to_sym)
    value = self.request_metadata.send(request_information_type.key.to_sym)
    return value.to_s if value.blank? or request_information_type.data_type != 'Date'
    return value.to_date.strftime('%d %B %Y')
  end

  def value_for(name, batch = nil)
    rit = RequestInformationType.find_by_name(name)
    if rit
      rit_value = self.get_value(rit)

      if rit_value.blank?
        self.value_for_decriptor(name, batch)
      else
        rit_value
      end
    else
      self.value_for_decriptor(name, batch)
    end
  end

  def value_for_decriptor(name, batch)
    desc = nil
    list = self.lab_events
    if batch
      list = self.lab_events_for_batch(batch)
    end
    list.each do |event|
      desc = event.descriptor_value_for(name)
      unless desc.nil?
        return desc
      end
    end
    unless desc.nil?
      desc
    else
      ""
    end
  end

  def mark_in_batch(batch, save_request=true)
    # =================
    # WARNING, this method should be called in batch#create_request but is "inlined" there instead (for performance reasons)
    # So make sure your update batch#create_requests accordingly
    # ===============
    # To ensure that the request isn't still viewable in the inbox.
    self.state = "started"
    self.save if save_request
  end

  def has_passed(batch, task)
    self.lab_events_for_batch(batch).each do |event|
      if event.description == task.name
        return true
      end
    end
    false
  end

  def lab_events_for_batch(batch)
    self.lab_events.find_all_by_batch_id(batch.id)
  end
  

  def event_with_key_value(k, v = nil)
    r = false
    unless v.nil?
      r = self.lab_events.all(:conditions => ["descriptors LIKE ?", "%#{k.to_s}: #{v.to_s}%" ])
      if r.empty?
        r = nil
      else
        r = r.first
      end
    end
    r
  end

  # This is used for the default next or previous request check.  It means that if the caller does not specify a
  # block then we can use this one in its place.
  PERMISSABLE_NEXT_REQUESTS = Object.new.tap do |permission|
    def permission.call(request)
      request.pending? or request.blocked?
    end
  end

  def next_requests(pipeline, &block)
    #TODO remove pipeline parameters
    # we filter according to the next pipeline
    next_pipeline = pipeline.next_pipeline
    #return [] if next_pipeline.nil?

    block ||= PERMISSABLE_NEXT_REQUESTS
    eligible_requests = if target_asset.present?
                          target_asset.requests
                        else
                          return [] if submission.nil?
                          submission.next_requests(self)
                        end

    eligible_requests.select { |r| (next_pipeline.nil? or next_pipeline.request_type_id == r.request_type_id) and block.call(r) }
  end

  def previous_failed_requests
    self.asset.requests.select { |previous_failed_request| (previous_failed_request.failed? or previous_failed_request.blocked?)}
  end

  def self.unhold_requests(request_proxys, save = true)
    request_proxys.each do |proxy|
      begin
        request = proxy.object
        if request.state == "hold"
          request.set_state("pending", save)
        end
      rescue
        next
      end
    end
  end


  def add_comment(comment, current_user)
    self.comments.create({:description => comment, :user_id => current_user.id})
  end

  def set_state(new_state, save=true)
    self.state = new_state
    self.save if save
  end

  def position(batch)
    batch.batch_requests.each do |br|
      if br.request_id == self.id
        return br.position
      end
      0
    end
  end

  def self.number_expected_for_submission_id_and_request_type_id(submission_id, request_type_id)
    Request.count(:conditions => "submission_id = #{submission_id} and request_type_id = #{request_type_id}")
  end

  def remove_unused_assets
    return if target_asset.nil?
    target_asset.requests do |related_request|
      target_asset.remove_unused_assets
      releated_request.asset.destroy
      releated_request.asset_id = nil
      releated_request.save!
    end
    self.target_asset.destroy
    self.target_asset_id = nil
    self.save!
  end

  def asset_parent_id
    AssetLink.ancestor_id asset_id if asset_id
  end

  def closed?
    ["passed", "failed", "cancelled", "aborted"].include?(self.state)
  end

  def open?
    ["pending", "started"].include?(self.state)
  end

  def batch_ids
    batch_requests.map { |br| br.batch_id }
  end

  def send_notification_email
    EventfulMailer.deliver_notify_request_fail(self.study.user.login, self.item, self, "Too many attempts")
  end

  def format_qc_information
    events = []
    unless self.lab_events.empty?
      self.events.each do |event|
        next if event.family.nil?

        message = event.message || "(No message was specified)"

        if event.family.downcase == "pass"
          events << {"event_id" => event.id, "status" => "pass", "message" => message, "created_at" => event.created_at}
        elsif event.family.downcase == "fail"
          events << {"event_id" => event.id, "status" => "fail", "message" => message, "created_at" => event.created_at}
        end
      end
    end
    events
  end

  def copy
    RequestFactory.copy_request(self)
  end
  
  def cancelable?
    if self.batch_requests.size == 0 && (pending? || blocked?)
      return true
    end
    false
  end

  def update_priority(pipeline)
    priority = ( self.priority + 1 ) % 2
    @asset = self.asset
    @asset.requests.each do |request|
      request.priority = priority
      request.save!
      next_request = request.next_requests(pipeline)
      next_request.each do |request_next|
        request_next.priority = priority
        request_next.save!
      end
    end
  end

  def update_priority_mx
    requests = Request.find_all_by_submission_id(self.submission_id)
    priority  = ( self.priority + 1 ) % 2
    requests.each do |request|
      request.priority = priority
      request.save
    end
  end
  
  def request_type_updatable?(new_request_type)
    return false unless self.pending?
    request_type = RequestType.find(new_request_type) 
    return true if self.request_type_id == request_type.id
    self.has_quota?(1)
  end

  extend Metadata
  has_metadata do
    # TODO[xxx]: Until we know exactly what to do with these they live here.
    # These are the metadata attributes that are updated by events.  As far as I am aware none of these
    # are actually displayed anywhere, so I'm not entirely sure why they exist at all.
    # 
    # TODO[xxx]: Actually we have to completely hide these otherwise the various request views are broken.
#    attribute(:batch_id)
#    attribute(:pipeline_id)
#    attribute(:pass)
#    attribute(:failure)
#    attribute(:library_creation_complete)
  end

  # NOTE: With properties Request#name would have been silently sent through to the property.  With metadata
  # we now need to be explicit in how we want it delegated.
  delegate :name, :to => :request_metadata
  def has_quota?(number)
    #no if one project doesn't have the quota
    not quotas.map(&:project).any? {|p| p.has_quota?(request_type_id, number) == false}
  end
end
