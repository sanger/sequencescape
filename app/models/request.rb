class Request < ActiveRecord::Base
  include ModelExtensions::Request
  include Aliquot::DeprecatedBehaviours::Request

  include Api::RequestIO::Extensions
  cattr_reader :per_page
  @@per_page = 500

  include Uuid::Uuidable
  include AASM
  include Commentable
  include Proxyable
  include StandardNamedScopes
  include Request::Statemachine
  extend Request::Statistics
  include Batch::RequestBehaviour

  extend EventfulRecord
  has_many_events
  has_many_lab_events

  self.inheritance_column = "sti_type"

  def self.delegate_validator
    DelegateValidation::AlwaysValidValidator
  end

    named_scope :for_pipeline, lambda { |pipeline|
      {
        :joins => [ 'LEFT JOIN pipelines_request_types prt ON prt.request_type_id=requests.request_type_id' ],
        :conditions => [ 'prt.pipeline_id=?', pipeline.id],
        :readonly => false
      }
    }

  named_scope :for_pooling_of, lambda { |plate|
    joins =
      if plate.stock_plate?
        [ 'INNER JOIN assets AS pw ON requests.asset_id=pw.id' ]
      else
        [
          'INNER JOIN well_links ON well_links.source_well_id=requests.asset_id',
          'INNER JOIN assets AS pw ON well_links.target_well_id=pw.id AND well_links.type="stock"',
        ]
      end
    {
      :select => 'uuids.external_id AS pool_id, GROUP_CONCAT(DISTINCT pw_location.description SEPARATOR ",") AS pool_into, requests.*',
      :joins => joins + [
        'INNER JOIN maps AS pw_location ON pw.map_id=pw_location.id',
        'INNER JOIN container_associations ON container_associations.content_id=pw.id',
        'INNER JOIN submissions ON requests.submission_id=submissions.id',
        'INNER JOIN uuids ON uuids.resource_id=submissions.id AND uuids.resource_type="Submission"'
      ],
      :group => 'submissions.id',
      :conditions => [
        'requests.sti_type NOT IN (?) AND container_associations.container_id=?',
        [TransferRequest,*Class.subclasses_of(TransferRequest)].map(&:name), plate.id
      ]
    }
  }

  belongs_to :pipeline
  belongs_to :item

  has_many :failures, :as => :failable
  has_many :billing_events

  has_many :request_quotas
  has_many :quotas, :through => :request_quotas

  belongs_to :request_type
  delegate :billable?, :to => :request_type, :allow_nil => true
  belongs_to :workflow, :class_name => "Submission::Workflow"

  named_scope :for_billing, :include => [ :initial_project, :request_type, { :target_asset => :aliquots } ]

  belongs_to :user

  belongs_to :submission

  named_scope :with_request_type_id, lambda { |id| { :conditions => { :request_type_id => id } } }

  # project is read only so we can set it everywhere
  # but it will be only used in specific and controlled place
  belongs_to :initial_project, :class_name => "Project"

  def project_id=(project_id)
    raise RuntimeError, "Initial project already set" if initial_project_id
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
    raise RuntimeError, "Initial study already set" if initial_study_id
    self.initial_study_id = study_id
  end

  def study=(study)
    return unless study
    self.study_id=study.id
  end

  #  validates_presence_of :study, :request_type#TODO, :submission

  named_scope :between, lambda { |source,target| { :conditions => { :asset_id => source.id, :target_asset_id => target.id } } }
  named_scope :into_by_id, lambda { |target_ids| { :conditions => { :target_asset_id => target_ids } } }

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
  named_scope :located, lambda {|location_id| { :joins => :location_association, :conditions =>  ['location_associations.location_id = ?', location_id ], :readonly => false } }

  #Use container location
  named_scope :holder_located, lambda { |location_id|
    {
      :joins => ["INNER JOIN container_associations hl ON hl.content_id = asset_id", "INNER JOIN location_associations ON location_associations.locatable_id = hl.container_id"],
      :conditions => ['location_associations.location_id = ?', location_id ],
      :readonly => false
    }
  }
  named_scope :holder_not_control, lambda {
    {
      :joins => ["INNER JOIN container_associations hncca ON hncca.content_id = asset_id", "INNER JOIN assets AS hncc ON hncc.id = hncca.container_id"],
      :conditions => ['hncc.sti_type != ?', 'ControlPlate' ],
      :readonly => false
    }
  }
  named_scope :without_asset, :conditions =>  'asset_id is null'
  named_scope :without_target, :conditions =>  'target_asset_id is null'
  named_scope :ordered, :order => ["id ASC"]
  named_scope :full_inbox, :conditions => {:state => ["pending","hold"]}
  named_scope :hold, :conditions => {:state => "hold"}

  named_scope :loaded_for_inbox_display, :include => [:comments, {:submission => {:orders =>:study}, :asset => [:scanned_into_lab_event,:comments,:studies]}]
  named_scope :ordered_for_ungrouped_inbox, :order => 'id DESC'
  named_scope :ordered_for_submission_grouped_inbox, :order => 'submission_id DESC, id ASC'

  named_scope :group_conditions, lambda { |conditions, variables| {
    :conditions => [ conditions.join(' OR '), *variables ]
  } }
  def self.group_requests(finder_method, options = {})
    target = options[:by_target] ? 'target_asset_id' : 'asset_id'

    send(finder_method, options.slice(:group).merge(
      :select  => "DISTINCT requests.*, tca.container_id AS container_id, tca.content_id AS content_id",
      :joins   => "INNER JOIN container_associations tca ON tca.content_id=#{target}",
      :readonly => false,
      :include => :request_metadata
    ))
  end

  named_scope :for_submission_id, lambda { |id| { :conditions => { :submission_id => id } } }
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

  named_scope :for_initial_study_id, lambda { |id| { :conditions  => {:initial_study_id => id } }
}




  delegate :study, :study_id, :to => :asset, :allow_nil => true

  named_scope :for_workflow, lambda { |workflow| { :joins => :workflow, :conditions => { :workflow => { :key => workflow } } } }
  named_scope :for_request_types, lambda { |types| { :joins => :request_type, :conditions => { :request_types => { :key => types } } } }

  named_scope :for_search_query, lambda { |query|
    { :conditions => [ 'id=?', query ] }
  }

  named_scope :find_all_target_asset, lambda { |target_asset_id| { :conditions => [ 'target_asset_id = ?', "#{target_asset_id}" ] } }
  named_scope :for_studies, lambda { |*studies| { :conditions => { :initial_study_id => studies.map(&:id) } } }

  named_scope :with_assets_for_starting_requests, :include => [:request_metadata,{:asset=>:aliquots,:target_asset=>:aliquots}]
  named_scope :not_failed, :conditions => ['state != ?', 'failed']

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

  def get_value(request_information_type)
    return '' unless self.request_metadata.respond_to?(request_information_type.key.to_sym)
    value = self.request_metadata.send(request_information_type.key.to_sym)
    return value.to_s if value.blank? or request_information_type.data_type != 'Date'
    return value.to_date.strftime('%d %B %Y')
  end

  def value_for(name, batch = nil)
    rit = RequestInformationType.find_by_name(name)
    rit_value = self.get_value(rit) if rit.present?
    return rit_value if rit_value.present?

    list = (batch.present? ? self.lab_events_for_batch(batch) : self.lab_events)
    list.each { |event| desc = event.descriptor_value_for(name) and return desc }
    ""
  end

  def has_passed(batch, task)
    self.lab_events_for_batch(batch).any? { |event| event.description == task.name }
  end

  def lab_events_for_batch(batch)
    self.lab_events.find_all_by_batch_id(batch.id)
  end

  def event_with_key_value(k, v = nil)
    v.nil? ? false : self.lab_events.with_descriptor(k, v).first
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

    eligible_requests.select do |r|
      ( next_pipeline.nil? or
        next_pipeline.request_types_including_controls.include?(r.request_type)
      ) and block.call(r)
    end
  end

  def previous_failed_requests
    self.asset.requests.select { |previous_failed_request| (previous_failed_request.failed? or previous_failed_request.blocked?)}
  end

  def add_comment(comment, current_user)
    self.comments.create({:description => comment, :user_id => current_user.id})
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

  def format_qc_information
    return [] if self.lab_events.empty?

    self.events.map do |event|
      next if event.family.nil? or not [ 'pass', 'fail' ].include?(event.family.downcase)

      message = event.message || "(No message was specified)"
      {"event_id" => event.id, "status" => event.family.downcase, "message" => message, "created_at" => event.created_at}
    end.compact
  end

  def copy
    RequestFactory.copy_request(self)
  end

  def cancelable?
    self.batch_request.nil? && (pending? || blocked?)
  end

  def update_priority
    priority = (self.priority + 1) % 2
    submission.requests.each do |request|
      request.update_attributes!(:priority => priority)
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

  # Adds any pool information to the structure so that it can be reported to client applications
  def update_pool_information(pool_information)
    # Does not need anything here
  end
end
