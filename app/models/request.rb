#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2013,2014,2015 Genome Research Ltd.
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

  def validator_for(request_option)
    request_type.request_type_validators.find_by_request_option!(request_option.to_s)
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
      :select => 'uuids.external_id AS pool_id, GROUP_CONCAT(DISTINCT pw_location.description ORDER BY pw.map_id ASC SEPARATOR ",") AS pool_into, requests.*',
      :joins => joins + [
        'INNER JOIN maps AS pw_location ON pw.map_id=pw_location.id',
        'INNER JOIN container_associations ON container_associations.content_id=pw.id',
        'INNER JOIN submissions ON requests.submission_id=submissions.id',
        'INNER JOIN uuids ON uuids.resource_id=submissions.id AND uuids.resource_type="Submission"'
      ],
      :group => 'requests.submission_id',
      :conditions => [
        'requests.sti_type NOT IN (?) AND container_associations.container_id=? AND submissions.state != "cancelled"',
        [TransferRequest,*Class.subclasses_of(TransferRequest)].map(&:name), plate.id
      ]
    }
  }

  named_scope :for_pre_cap_grouping_of, lambda { |plate|
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
      :select => 'min(uuids.external_id) AS group_id, GROUP_CONCAT(DISTINCT pw_location.description SEPARATOR ",") AS group_into, requests.*',
      :joins => joins + [
        'INNER JOIN maps AS pw_location ON pw.map_id=pw_location.id',
        'INNER JOIN container_associations ON container_associations.content_id=pw.id',
        'INNER JOIN pre_capture_pool_pooled_requests ON requests.id=pre_capture_pool_pooled_requests.request_id',
        'INNER JOIN uuids ON uuids.resource_id=pre_capture_pool_pooled_requests.pre_capture_pool_id AND uuids.resource_type="PreCapturePool"'
      ],
      :group => 'pre_capture_pool_pooled_requests.pre_capture_pool_id',
      :conditions => [
        'requests.sti_type NOT IN (?) AND container_associations.container_id=? AND requests.state="pending"',
        [TransferRequest,*Class.subclasses_of(TransferRequest)].map(&:name), plate.id
      ]
    }
  }

  named_scope :for_order_including_submission_based_requests, lambda {|order|
    # To obtain the requests for an order and the sequencing requests of its submission (as they are defined
    # as a common element for any order in the submission)
    {
      :conditions => ['requests.order_id=? OR (requests.order_id IS NULL AND requests.submission_id=?)', order.id, order.submission.id]
    }
  }

  belongs_to :pipeline
  belongs_to :item

  has_many :failures, :as => :failable

  belongs_to :request_type, :inverse_of => :requests
  delegate :billable?, :to => :request_type, :allow_nil => true
  belongs_to :workflow, :class_name => "Submission::Workflow"

  named_scope :for_billing, :include => [ :initial_project, :request_type, { :target_asset => :aliquots } ]

  belongs_to :user

  belongs_to :submission, :inverse_of => :requests
  belongs_to :order, :inverse_of => :requests

  has_many :submission_siblings, :through => :submission, :source => :requests, :class_name => 'Request', :conditions => {:request_type_id => '#{request_type_id}'}

  named_scope :with_request_type_id, lambda { |id| { :conditions => { :request_type_id => id } } }

  named_scope :for_pacbio_sample_sheet, :include => [{:target_asset=>:map},:request_metadata]

  # project is read only so we can set it everywhere
  # but it will be only used in specific and controlled place
  belongs_to :initial_project, :class_name => "Project"

  has_many :request_events, :order => 'current_from ASC'
  def current_request_event
    request_events.current.last
  end

  def project_id=(project_id)
    raise RuntimeError, "Initial project already set" if initial_project_id
    self.initial_project_id = project_id
  end


  def submission_plate_count
    submission.requests.find(:all,
      :conditions=>{:request_type_id=>request_type_id},
      :joins=>'LEFT JOIN container_associations AS spca ON spca.content_id = requests.asset_id',
      :group=>'spca.container_id'
    ).count
  end


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

  def associated_studies
    return [initial_study] if initial_study.present?
    return asset.studies.uniq if asset.present?
    return submission.studies if submission.present?
    []
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
      when request_type.is_a?(Array) then request_type
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
  named_scope :with_asset_location, :include => { :asset => :map }

  named_scope :siblings_of, lambda {|request| { :conditions => ['asset_id = ? AND NOT id = ?', request.asset_id, request.id ] } }

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
  named_scope :excluding_states, lambda { |states|
    {
      :conditions => [states.map{|s| '(state != ?)' }.join(" OR "), states].flatten
    }
  }
  named_scope :ordered, :order => ["id ASC"]
  named_scope :full_inbox, :conditions => {:state => ["pending","hold"]}
  named_scope :hold, :conditions => {:state => "hold"}

  # Setup inbox eager loading
  named_scope :loaded_for_inbox_display, :include => {:submission => {:orders =>:study}, :asset => [:scanned_into_lab_event,:studies]}
  named_scope :loaded_for_grouped_inbox_display, :include => [ {:submission => :orders}, :asset , :target_asset, :request_type ]

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
      :joins =>  'INNER JOIN aliquots AS al ON requests.asset_id = al.receptacle_id',
      :group => "requests.id",
      :conditions =>['al.study_id IN (?)',ids]
    }
  } do
    #fix a bug in rail, the group clause if removed
    #therefor we need to the DISTINCT parameter
    def count
      super('requests.id',:distinct =>true)
    end
  end
  named_scope :for_study_id, lambda { |id|
    {
      :joins =>  'INNER JOIN aliquots AS al ON requests.asset_id = al.receptacle_id',
      :group => "requests.id",
      :conditions =>['al.study_id = ?',id]
    }
  } do
    #fix a bug in rail, the group clause if removed
    #therefor we need to the DISTINCT parameter
    def count
      super('requests.id',:distinct =>true)
    end
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

  named_scope :for_search_query, lambda { |query,with_includes|
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

  def target_tube
    target_asset if target_asset.is_a?(Tube)
  end

  def previous_failed_requests
    self.asset.requests.select { |previous_failed_request| (previous_failed_request.failed? or previous_failed_request.blocked?)}
  end

  def add_comment(comment, user)
    self.comments.create({:description => comment, :user => user})
  end

  def self.number_expected_for_submission_id_and_request_type_id(submission_id, request_type_id)
    Request.count(:conditions => "submission_id = #{submission_id} and request_type_id = #{request_type_id}")
  end

  def return_pending_to_inbox!
    raise StandardError, "Can only return pending requests, request is #{state}" unless pending?
    remove_unused_assets
  end

  def remove_unused_assets
    ActiveRecord::Base.transaction do
      return if target_asset.nil?
      self.target_asset.ancestors.clear
      self.target_asset.destroy
      self.save!
    end
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
    priority = (self.priority + 1) % 4
    submission.update_attributes!(:priority => priority)
  end

  def priority
    submission.try(:priority)||0
  end

  def request_type_updatable?(new_request_type)
    self.pending?
  end

  def customer_accepts_responsibility!
    self.request_metadata.update_attributes!(:customer_accepts_responsibility=>true)
  end

  extend Metadata
  has_metadata do

  end

  # NOTE: With properties Request#name would have been silently sent through to the property.  With metadata
  # we now need to be explicit in how we want it delegated.
  delegate :name, :to => :request_metadata

  # Adds any pool information to the structure so that it can be reported to client applications
  def update_pool_information(pool_information)
    # Does not need anything here
  end

  def submission_siblings
    submission.requests.with_request_type_id(request_type_id)
  end

  # The date at which the submission was made. In most cases this will be similar to the request's created_at
  # timestamp. We go via submission to ensure that copied requests bear the original timestamp.
  def submitted_at
    # Hopefully we shouldn't get any requests that don't have a submission. But validation is turned off, so
    # we should assume it it possible.
    return '' if submission.nil?
    submission.created_at.strftime('%Y-%m-%d')
  end

  def role
    order.try(:role)
  end

  def self.accessioning_required?
    false
  end

  def ready?
    true
  end

  def target_purpose
    nil
  end

  def library_creation?
    false
  end

  def manifest_processed!; end
end
