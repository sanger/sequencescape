class Study < ActiveRecord::Base
  acts_as_audited :on => [:destroy, :update]

  include StudyReport::StudyDetails
  include ModelExtensions::Study

  include Api::StudyIO::Extensions
  cattr_reader :per_page
  @@per_page = 500
  include Uuid::Uuidable

  include EventfulRecord
  include AASM
  include DataRelease
  include Commentable
  include Identifiable
  include Named
  include ReferenceGenome::Associations
  include SampleManifest::Associations

  extend EventfulRecord
  has_many_events
  has_many_lab_events
  
  acts_as_authorizable

  aasm_column :state
  aasm_initial_state :pending
  aasm_state :pending
  aasm_state :active, :enter => :mark_active
  aasm_state :inactive, :enter => :mark_deactive

  aasm_event :reset do
    transitions :to => :pending, :from => [:inactive, :active]
  end

  aasm_event :activate do
    transitions :to => :active, :from => [:pending, :inactive]
  end

  aasm_event :deactivate do
    transitions :to => :inactive, :from => [:pending, :active]
  end

  attr_accessor :approval
  attr_accessor :run_count
  attr_accessor :total_price

  include Role::Authorized
  role_relation(:followed_by,       'follower')
  role_relation(:managed_by,        'manager')
  role_relation(:collaborated_with, 'collaborator')

  has_many_users_through_roles(:owners)
  has_many_users_through_roles(:managers)
  has_many_users_through_roles(:followers)
  has_many_users_through_roles(:"Data Access Contacts")

  belongs_to :user

  has_many :study_samples #, :group => 'study_id, sample_id', :conditions => 'sample_id IS NOT NULL'
  has_many :submissions
  has_many :samples, :through => :study_samples
  has_many :batches
  has_many :requests
  has_many :asset_groups
  has_many :study_reports

  #load all the associated requests with attemps and request type
  has_many :eager_items , :class_name => "Item", :include => [{:requests => [:request_type]}], :through => :requests, :source => :item # , :uniq => true
  has_many :assets , :class_name => "Asset", :through => :requests, :source => :asset, :uniq => true 

  has_many :items , :through => :requests, :uniq => true

  # This is a performance enhancement!  Projects and studies are related through
  # requests but the requests table can be huge, and then performance can really
  # suck (200s load times for 100 studies when eager loading projects).  Instead
  # this reduces the requests for this study down to unique projects, and then
  # says use those unique projects.  That knocks times down to 0.15s for the same
  # studies!
  has_many :project_requests, :class_name => 'Request', :group => 'study_id, project_id', :conditions => 'project_id IS NOT NULL'
  has_many :projects, :class_name => "Project", :through => :project_requests, :source => :project, :uniq => true

  has_many :comments, :as => :commentable
  has_many :events, :as => :eventful
  has_many :documents, :as => :documentable
  has_many :sample_manifests
  has_many :suppliers, :through => :sample_manifests, :uniq => true

  include StudyRelation::Associations

  validates_presence_of :name
  validates_uniqueness_of :name, :on => :create, :message => "already in use (#{self.name})"
  validates_format_of :abbreviation, :with => /^[\w_-]+$/i, :allow_blank => false, :message => 'cannot contain spaces or be blank'

  named_scope :for_search_query, lambda { |query|
    { :conditions => [ 'name LIKE ? OR id=?', "%#{query}%", query ] }
  }

  named_scope :with_no_ethical_approval, { :conditions => { :ethically_approved => false } }

  named_scope :is_active,   { :conditions => { :state => 'active'   } }
  named_scope :is_inactive, { :conditions => { :state => 'inactive' } }
  named_scope :is_pending,  { :conditions => { :state => 'pending'  } }

  named_scope :newest_first, { :order => "#{ self.quoted_table_name }.created_at DESC" }
  named_scope :with_user_included, { :include => :user }

  YES = 'Yes'
  NO  = 'No'
  YES_OR_NO = [ YES, NO ]
  Other_type = "Other"

  STUDY_SRA_HOLDS = [ 'Hold', 'Public' ]
  
  DATA_RELEASE_STRATEGY_OPEN = 'open'
  DATA_RELEASE_STRATEGY_MANAGED = 'managed'
  DATA_RELEASE_STRATEGY_NOT_APPLICABLE = 'not applicable'
  DATA_RELEASE_STRATEGIES = [ DATA_RELEASE_STRATEGY_OPEN, DATA_RELEASE_STRATEGY_MANAGED, DATA_RELEASE_STRATEGY_NOT_APPLICABLE ]

  DATA_RELEASE_TIMING_STANDARD = 'standard'
  DATA_RELEASE_TIMING_NEVER    = 'never'
  DATA_RELEASE_TIMING_DELAYED  = 'delayed'
  DATA_RELEASE_TIMINGS = [
    DATA_RELEASE_TIMING_STANDARD,
    'immediate',
    DATA_RELEASE_TIMING_DELAYED,
    DATA_RELEASE_TIMING_NEVER
  ]
  DATA_RELEASE_PREVENTION_REASONS = [
    'data validity',
    'legal'
  ]

  DATA_RELEASE_DELAY_FOR_OTHER = 'other'
  DATA_RELEASE_DELAY_REASONS = [
    'phd study',
    DATA_RELEASE_DELAY_FOR_OTHER
  ]

  DATA_RELEASE_DELAY_LONG  = [ '6 months', '9 months', '12 months' ]
  DATA_RELEASE_DELAY_SHORT = [ '3 months' ]
  DATA_RELEASE_DELAY_PERIODS = DATA_RELEASE_DELAY_SHORT + DATA_RELEASE_DELAY_LONG

  extend Metadata
  has_metadata do
    include StudyType::Associations
    include DataReleaseStudyType::Associations
    include ReferenceGenome::Associations
    include FacultySponsor::Associations
    
    association(:study_type, :name)
    association(:data_release_study_type, :name)
    association(:reference_genome, :name)
    association(:faculty_sponsor, :name)
    
    attribute(:study_description, :required => true)
    attribute(:contaminated_human_dna, :required => true, :in => YES_OR_NO)
    attribute(:study_project_id)
    attribute(:study_abstract)
    attribute(:study_study_title)
    attribute(:study_ebi_accession_number)
    attribute(:study_sra_hold, :required => true, :default => 'Hold', :in => STUDY_SRA_HOLDS)
    attribute(:contains_human_dna, :required => true, :in => YES_OR_NO)
    attribute(:commercially_available, :required => true, :in => YES_OR_NO)    
    attribute(:study_name_abbreviation)

    attribute(:data_release_strategy, :required => true, :in => DATA_RELEASE_STRATEGIES)
    attribute(:data_release_standard_agreement, :default => YES, :in => YES_OR_NO, :if => :managed?)

    attribute(:data_release_timing, :required => true, :default => DATA_RELEASE_TIMING_STANDARD, :in => DATA_RELEASE_TIMINGS)
    attribute(:data_release_delay_reason, :required => true, :in => DATA_RELEASE_DELAY_REASONS, :if => :delayed_release?)
    attribute(:data_release_delay_period, :required => true, :in => DATA_RELEASE_DELAY_PERIODS, :if => :delayed_release?)
    attribute(:bam, :default => true)

    with_options(:required => true, :if => :delayed_for_other_reasons?) do |required|
      required.attribute(:data_release_delay_other_comment)
      required.attribute(:data_release_delay_reason_comment)
    end

    attribute(:dac_policy)
    attribute(:ega_dac_accession_number)
    attribute(:ega_policy_accession_number)
    attribute(:array_express_accession_number)

    with_options(:if => :delayed_for_long_time?, :required => true) do |required|
      required.attribute(:data_release_delay_approval, :in => YES_OR_NO)
    end

    with_options(:if => :never_release?, :required => true) do |required|
      required.attribute(:data_release_prevention_reason, :in => DATA_RELEASE_PREVENTION_REASONS)
      required.attribute(:data_release_prevention_approval, :in => YES_OR_NO)
      required.attribute(:data_release_prevention_reason_comment)
    end

    # SNP information
    attribute(:snp_study_id, :integer => true)
    attribute(:snp_parent_study_id, :integer => true)
    
    REMAPPED_ATTRIBUTES = {
      :contaminated_human_dna     => YES_OR_NO,
      :study_sra_hold             => STUDY_SRA_HOLDS,
      :contains_human_dna         => YES_OR_NO,
      :commercially_available     => YES_OR_NO
    }.inject({}) do |h,(k,v)|
      h[k] = v.inject({}) { |a,b| a[b.downcase] = b ; a }
      h
    end

    before_validation do |record|
      record.reference_genome_id = 1 if record.reference_genome_id.blank?

      # Unfortunately it appears that some of the functionality of this implementation relies on non-capitalisation!
      # So we remap the lowercased versions to their proper values here
      REMAPPED_ATTRIBUTES.each do |attribute,mapping|
        record[attribute] = mapping.fetch(record[attribute].try(:downcase), record[attribute])
        record[attribute] = nil if record[attribute].blank? # Empty strings should be nil
      end
    end
  end
  class Metadata
    def managed?
      self.data_release_strategy == DATA_RELEASE_STRATEGY_MANAGED
    end

    def delayed_release?
      self.data_release_timing == DATA_RELEASE_TIMING_DELAYED
    end

    def never_release?
      self.data_release_timing == DATA_RELEASE_TIMING_NEVER
    end

    def delayed_for_other_reasons?
      self.data_release_delay_reason == DATA_RELEASE_DELAY_FOR_OTHER
    end

    def delayed_for_long_time?
      DATA_RELEASE_DELAY_PERIODS.include?(self.data_release_delay_period)
    end

    has_one :data_release_non_standard_agreement, :class_name => 'Document', :as => :documentable
    accepts_nested_attributes_for :data_release_non_standard_agreement
    validates_presence_of :data_release_non_standard_agreement, :if => :non_standard_agreement?
    validates_associated  :data_release_non_standard_agreement, :if => :non_standard_agreement?

    before_validation do |record|
      if not record.non_standard_agreement? and not record.data_release_non_standard_agreement.nil?
        record.data_release_non_standard_agreement.delete
        record.data_release_non_standard_agreement = nil
      end
    end

    def non_standard_agreement?
      self.data_release_standard_agreement == NO
    end

    def study_type_valid?
      self.errors.add(:study_type, "is not specified")  if study_type.name == "Not specified"
    end
    
    def data_release_study_type_valid?
      self.errors.add(:data_release_study_type, "is not specified")  if data_release_study_type.name == "not specified"
    end

    with_options(:if => :validating_ena_required_fields?) do |ena_required_fields|
      ena_required_fields.validates_presence_of :data_release_strategy
      ena_required_fields.validates_presence_of :data_release_timing
      ena_required_fields.validates_presence_of :study_description
      ena_required_fields.validates_presence_of :study_abstract
      ena_required_fields.validates_presence_of :study_study_title
      ena_required_fields.validate :study_type_valid?
      ena_required_fields.validate :data_release_study_type_valid? 
    end

    def snp_parent_study
      return nil if self.snp_parent_study_id.nil?
      self.class.first(:conditions => { :snp_study_id => self.snp_parent_study_id }, :include => :study).try(:study)
    end

    def snp_child_studies
      return nil if self.snp_study_id.nil?
      self.class.all(:conditions => { :snp_parent_study_id => self.snp_study_id }, :include => :study).map(&:study)
    end
  end

  # We only need to validate the field if we are enforcing data release
  def validating_ena_required_fields_with_enforce_data_release=(state)
    self.validating_ena_required_fields_without_enforce_data_release = state if self.enforce_data_release
  end
  alias_method_chain(:validating_ena_required_fields=, :enforce_data_release)

  def mark_deactive
    unless self.inactive?
      logger.warn "Study deactivation failed! #{self.errors.map{|e| e.to_s} }"
    end
  end

  def mark_active
    unless self.active?
      logger.warn "Study activation failed! #{self.errors.map{|e| e.to_s} }"
    end
  end

  def completed
    if (self.requests.size - self.requests.failed.size - self.requests.cancelled.size) > 0
      completed_percent = ((self.requests.passed.size.to_f / (self.requests.size - self.requests.failed.size - self.requests.cancelled.size).to_f)*100)
      completed_percent.to_i
    else
      return 0
    end
  end

  def submissions_for_workflow(workflow)
    self.submissions.select {|s| s.workflow.id == workflow.id}
  end


  # TODO - Move these to named scope on Request
  def total_requests(request_type)
    self.requests.request_type(request_type).count
  end

  def completed_requests(request_type)
    self.requests.request_type(request_type).completed.count
  end

  def passed_requests(request_type)
    self.requests.request_type(request_type).passed.count
  end

  def failed_requests(request_type)
    self.requests.request_type(request_type).failed.count
  end

  def pending_requests(request_type)
    self.requests.request_type(request_type).pending.count
  end


  def started_requests(request_type)
    self.requests.request_type(request_type).started.count
  end

  def cancelled_requests(request_type)
    self.requests.request_type(request_type).cancelled.count
  end

  def study_status
    self.inactive? ? "closed" : "open"
  end

  def dac_refname
    "DAC for study - #{name} - ##{self.id}"
  end

  def unprocessed_submissions?
    unless study.submissions.unprocessed.all.size == 0
      true
    else
      false
    end
  end
  ### TODO - Everything below should be treated as legacy until cleaned

  # Used by EventfulMailer
  def study
    self
  end

  # Checks if a user is following THIS study
  def followed_by?(user)
    user.following? self
  end

  # Returns the study owner (user) if exists or nil
  # TODO - Should be "owners" and return all owners or empty array - done
  # TODO - Look into this is the person that created it really the owner?
  # If so, then an owner should be created when a study is created.

  def owner
    owners.first
  end

  def locale
    self.funding_source
  end

  def total_requested(ended)
    count = 0
    ended_items(ended).each do |item|
      count = count + item.total_requested
    end
    count
  end


  def ended_items(ended)
    i = []
    self.samples.each do |sample|
      if sample.matches_end? ended
        sample.items.each do |item|
          i.push item
        end
      end
    end
    i
  end

  def add_reference(params = {})
    #if the assembly is a curated one from titan
    if params[:assembly][:reference]
      @reference = Sequence.find(params[:assembly][:reference])
      self.add_reference_descriptors(@reference)
      return true
    #if it isn't (i.e. instead it's a file uploaded by the user)
    elsif params[:assembly][:kind] == "None"
      return true
    elsif params[:assembly][:kind] == ""
      return true
    else
      @sequence = Sequence.new(params[:assembly])
      @sequence.name = self.id.to_s
      @sequence.set_prefix(self.class.to_s.downcase)
      if @sequence.save
        self.add_reference_descriptors(@sequence)
      else
        return false
      end
    end
  end

  named_scope :awaiting_ethical_approval, {
    :joins => :study_metadata,
    :conditions => {
      :ethically_approved => false,
      :study_metadata => {
        :contains_human_dna => Study::YES,
        :contaminated_human_dna => Study::NO,
        :commercially_available => Study::NO
      }
    }
  }

  named_scope :contaminated_with_human_dna, {
    :joins => :study_metadata,
    :conditions => {
      :study_metadata => {
        :contaminated_human_dna => Study::YES
      }
    }
  }

  def self.all_awaiting_ethical_approval
    self.awaiting_ethical_approval
  end
 
  def self.all_contaminated_with_human_dna
    self.contaminated_with_human_dna
  end

  def ebi_accession_number
    self.study_metadata.study_ebi_accession_number
  end

  def dac_accession_number
    self.study_metadata.ega_dac_accession_number
  end

  def policy_accession_number
    self.study_metadata.ega_policy_accession_number
  end

  def accession_number?
    not ebi_accession_number.blank?
  end

  def data_release_strategy
    self.study_metadata.data_release_strategy
  end

  def abbreviation
    abbreviation = self.study_metadata.study_name_abbreviation 
    abbreviation.blank? ?  "#{self.id}STDY" : abbreviation
  end

  def dehumanise_abbreviated_name
    self.abbreviation.downcase.gsub(/ +/,'_')
  end

  def approved?
    #TODO remove
    true
  end
  
  def accession_service
    if data_release_strategy == "open"
      return EraAccessionService.new
    elsif data_release_strategy == "managed"
      return EgaAccessionService.new
    end
  end



  def accession_service
    if data_release_strategy == "open"
      return EraAccessionService.new
    elsif data_release_strategy == "managed"
      return EgaAccessionService.new
    end
    
    nil
  end

  def validate_ena_required_fields!
    self.validating_ena_required_fields = true
    self.valid? or raise ActiveRecord::RecordInvalid, self
  ensure
    self.validating_ena_required_fields = false
  end
  
  def mailing_list_of_managers
    receiver = self.managers.map(&:email).compact.uniq
    receiver =  User.all_administrators_emails if receiver.empty?
    return receiver
  end

  # return true if yes, false if not , and nil if we don't know
  def affiliated_with?(object)
    case
    when object.respond_to?(:study_id)
      self.id == object.study_id
    when object.respond_to?(:study_ids)
      object.study_ids.include?(self.id)
    else
      nil
    end
  end

  def decide_if_object_should_be_taken(study_from, sample, object)
    case study_from.affiliated_with?(object)
    when true
      # don't propagate asset from another sample
      return object unless object.is_a?(Aliquot::Receptacle)
      object_sample = object.primary_aliquot.try(:sample)
      (object_sample.present? and object_sample != sample) ? nil : object

    when false then nil # we skip the object and its dependencies
    else [] # don't return the object but check it's dependencies
    end
  end
  private :decide_if_object_should_be_taken

  # return the list of objects which haven't been successfully saved
  # that's the caller responsibilitie to wrap the call in a transaction if needed
  def take_sample(sample, study_from, user, asset_group)
    errors = []
    assets_to_move = sample.assets.select { |a| study_from.affiliated_with?(a) && a.is_a?(SampleTube) }

    raise RuntimeError, "study_from not specified. Can't move a sample to a new study" unless study_from
    helper = lambda { |object| decide_if_object_should_be_taken(study_from, sample, object) }
    objects_to_move = 
      sample.walk_objects(
        :sample     => [:receptacles, :study_samples],
        :request    => :item,
        :asset      => [ :requests, :parents, :children ],
        :well       => :plate,
        &helper
      )

                                    #we duplicate each submission and reassign moved requests to it
    objects_to_move.each do |object|
      take_object(object, user, study_from)
      begin
      object.save!
    rescue Exception => ex
      errors << ex.message
    end
    end

    if asset_group
      assets_to_move.each do |asset|
        asset_groups = asset.asset_groups.reject { |ag| ag.study == study_from }
        asset_groups << asset_group
        asset.asset_groups = asset_groups
        asset.save
      end
    end
    if errors.present?
      errors.each { |error | sample.errors.add("Move:", error) }
      false
    else
       true
    end
  end


  private
  # beware , this method change the study of an object but doesn't look at some 
  #  eventual dependencies.
  def take_object(object, user, study_from)
    # we don't check if the object is related to study from. because this can change 
    # if the object is  related through and we have just changed the association
    # (example asset and via Request)
    if object.respond_to?(:study=)
      object.study = self
    end

    if object.respond_to?(:events) 
      object.events.create(
        :message => (study_from ? "#{object.class.name} #{object.id} is moved from Study  #{study_from.id} to Study #{self.id}" :  "#{object.class.name} #{object.id} is moved to Study #{self.id}"),
        :created_by => user.login,
        :content => "#{object.class.name} moved by #{user.login}",
        :of_interest_to => "administrators"
      )
    end
  end
end
