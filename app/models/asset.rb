class Asset < ActiveRecord::Base
  include StudyReport::AssetDetails
  include ModelExtensions::Asset

  class VolumeError< StandardError
  end

  before_create :set_default_prefix
  
  class_inheritable_accessor :prefix
  self.prefix = "NT"
  
  cattr_reader :per_page
  @@per_page = 500
  self.inheritance_column = "sti_type"
  #acts_as_paranoid
#  validates_uniqueness_of :name

  has_many :asset_group_assets
  has_many :asset_groups, :through => :asset_group_assets
  has_many :requests
  has_one :source_request, :class_name => "Request", :foreign_key => :target_asset_id
  has_many :asset_audits
  
  # Contents
  belongs_to :sample
  alias_attribute(:material, :sample)
  alias_attribute(:material_id, :sample_id)
  def material_type ; Sample.name ; end

  extend ContainerAssociation::Extension

  # to override in subclass
  def location
    nil
  end

  # Holder
  # Replaced by container
  #belongs_to :holder, :polymorphic => true
  # Replaced by contents
  #has_many :holded_assets, :as => :holder, :class_name => "Asset"
  belongs_to :map
  belongs_to :barcode_prefix
  named_scope :sorted , :order => "map_id ASC"
  named_scope :position_name, lambda { |*args| { :joins => :map, :conditions => ["description = ? AND asset_size = ?", args[0], args[1]] }}
  named_scope :get_by_type, lambda {|*args| {:conditions => { :sti_type => args[0]} } }

  has_many :studies, :class_name => "Study", :through => :requests, :source => :study, :uniq => true

  # Named scope for search by query string behaviour
  named_scope :for_search_query, lambda { |query|
    {
      :conditions => [
        'assets.name IS NOT NULL AND (assets.name LIKE :like OR assets.id=:query OR assets.barcode LIKE :query)', { :like => "%#{query}%", :query => query } ],
      :include => :requests, :order => 'requests.pipeline_id ASC'
    }
  }

  named_scope :with_name, lambda { |*names| { :conditions => { :name => names.flatten } } }

  # Relationships to other assets
  has_dag_links :link_class_name => 'AssetLink'
  acts_as_audited :on => [:destroy, :update]
  

  extend EventfulRecord
  has_many_events do 
    event_constructor(:create_external_release!,       ExternalReleaseEvent,          :create_for_asset!)
    event_constructor(:create_pass!,                   Event::AssetSetQcStateEvent,   :create_passed!)
    event_constructor(:create_fail!,                   Event::AssetSetQcStateEvent,   :create_failed!)
    event_constructor(:create_scanned_into_lab!,       Event::ScannedIntoLabEvent,    :create_for_asset!)
    event_constructor(:create_plate!,                  Event::PlateCreationEvent,     :create_for_asset!)
    event_constructor(:create_plate_with_date!,        Event::PlateCreationEvent,     :create_for_asset_with_date!)
    event_constructor(:create_sequenom_stamp!,         Event::PlateCreationEvent,     :create_sequenom_stamp_for_asset!)
    event_constructor(:create_sequenom_plate!,         Event::PlateCreationEvent,     :create_sequenom_plate_for_asset!)
    event_constructor(:create_gel_qc!,                 Event::SampleLogisticsQcEvent, :create_gel_qc_for_asset!)
    event_constructor(:create_pico!,                   Event::SampleLogisticsQcEvent, :create_pico_result_for_asset!)
    event_constructor(:created_using_sample_manifest!, Event::SampleManifestEvent,    :created_sample!)
    event_constructor(:updated_using_sample_manifest!, Event::SampleManifestEvent,    :updated_sample!)
    event_constructor(:update_gender_markers!,         Event::SequenomLoading,        :created_update_gender_makers!)
    event_constructor(:update_sequenom_count!,         Event::SequenomLoading,        :created_update_sequenom_count!)
  end
  has_many_lab_events

  has_one_event_with_family 'scanned_into_lab'
  has_one_event_with_family 'moved_to_2d_tube'

  # Key/value stores and attributes
  include ExternalProperties
  acts_as_descriptable :serialized
  include PolymorphicAttributable
  include Uuid::Uuidable

  # Links to other databases
  include Identifiable

  include Commentable
  include Event::PlateEvents

  #set_polymorphic_attributes :sample

  # Returns the request options used to create this asset.  By default assumed to be empty.
  def created_with_request_options
    {}
  end

  def is_sequenceable?
    false
  end

  # Returns the type of asset that can be considered appropriate for request types.
  def asset_type_for_request_types
    self.class
  end

  def tube_name
    return self.sample.shorten_sanger_sample_id if self.sample && ! self.sample.sanger_sample_id.blank?
    self.name
  end

  def study
    studies.first
  end

  has_one :creation_request, :class_name => 'Request', :foreign_key => :target_asset_id

  def label
    self.sti_type || 'Unknown'
  end

  def label=(new_type)
    self.sti_type = new_type
  end

  def request_types
    RequestType.find(:all, :conditions => {:asset_type => label})
  end

  def scanned_in_date
    self.scanned_into_lab_event.try(:content) || ''
  end
  
  def api_scanned_in_date
    date = scanned_in_date
    return date if date.blank?
    date+" 03:00:00"
  end

  def moved_to_2D_tube_date
    self.moved_to_2d_tube_event.try(:content) || ''
  end

  def create_asset_group_wells(user, params)
    asset_group = AssetGroup.create(params)
    asset_group.user = user
    asset_group.assets = wells
    asset_group.save!

    # associate sample to study
    if asset_group.study
      wells.each do |well|
        next unless well.sample
        well.sample.studies<< asset_group.study
        well.sample.save!
      end
    end

    asset_group

  end

  def move_quaratine(study, user)
    self.events << Event.new({:message => "Moved to study #{study.id}", :created_by => user.login, :family => "Update"})
    # Move all requests
    self.requests.each do |request|
      request.events << Event.new({:message => "Moved from study #{request.study_id} to study #{study.id}", :created_by => user.login, :family => "Update"})
      request.study_id = study.id
      request.save
    end
  end

  after_create :generate_name_with_id, :if => :name_needs_to_be_generated?

  def name_needs_to_be_generated?
    @name_needs_to_be_generated
  end
  private :name_needs_to_be_generated?

  def generate_name_with_id
    self.update_attributes!(:name => "#{self.name} #{self.id}")
  end

  def generate_name(new_name)
    self.name = new_name
    @name_needs_to_be_generated = self.library_prep?
  end

  #todo unify with parent/children
  def parent
    self.parents.first
  end

  def child
    self.children.last
  end

  def library_prep?
    if self.sti_type == "LibraryTube" || self.sti_type == "MultiplexedLibraryTube"
      return true
    else
      return false
    end
  end

  def display_name
    if self.name.nil? || self.name.empty?
      return "#{self.sti_type} #{self.id}"
    else
      self.name
    end
  end

  def is_a_pool?
    false
  end

  def qc_fail
    self.qc_state = "failed"
    self.save
  end

  def qc_pass
    self.qc_state = "passed"
    self.save
  end
  
  def qc_pending
    self.qc_state = "pending"
    self.save!
  end

  def compatible_qc_state
    if self.qc_state == "passed"
      "pass"
    elsif self.qc_state == "failed"
      "fail"
    else 
			return self.qc_state
    end
  end

#  def prefix
#    if barcode_prefix
#      barcode_prefix.prefix
#    else
#      "NT"
#    end
#  end

  def underlying_sampletube
    return
  end

  def move_asset_group(study_from, asset_group)
    return
  end

  def move_study_sample(study_from, study_to, current_user)
    return
  end

  def list_sample_tube(asset_visited, sampletube_list)
    unless asset_visited.include?(self.id)
      asset_visited << self.id
      self.children.each do |child|
        unless asset_visited.include?(child.id)
          child.list_sample_tube(asset_visited, sampletube_list)
        end
      end

      self.parents.each do |parent|
        unless asset_visited.include?(parent.id)
          parent.list_sample_tube(asset_visited, sampletube_list)
        end
      end
      sampletube_list << self  unless self.underlying_sampletube.nil?
    end
  end

  def studies_list
    asset_visited = []
    sampletube_list = []
    @studies = []
    self.list_sample_tube(asset_visited, sampletube_list)

    sampletube_list.each do |sampletube|
     @studies << sampletube.studies
    end

    @studies = @studies.flatten.uniq
    return @studies
  end

  def move_all_asset_group(study_from, study_to, asset_visited, asset_group, current_user)
    unless asset_visited.include?(self.id)
      asset_visited << self.id
      self.children.each do |child|
        unless asset_visited.include?(child.id)
          child.move_all_asset_group(study_from, study_to, asset_visited, asset_group, current_user)
        end
      end

      self.parents.each do |parent|
        unless asset_visited.include?(parent.id)
          parent.move_all_asset_group(study_from, study_to, asset_visited, asset_group, current_user)
        end
      end

      self.move_asset_requests(study_from, study_to)
      self.move_asset_group(study_from, asset_group)   # only subclass sampleTube
      self.move_study_sample(study_from, study_to, current_user) # only subclass sampleTube
    end
  end


  def move_asset_requests(study_from, study_to)
    requests = self.requests.find_all_by_study_id(study_from.id)
    requests.each do |request|
      request.study_id = study_to.id
      request.save!
    end
    #puts self.id
  end

  def move_to_asset_group(study_from, study_to, asset_group, new_assets_name, current_user)
    move_result = true
    begin
      ActiveRecord::Base.transaction do
        asset_visited = []
        move_all_asset_group(study_from, study_to, asset_visited, asset_group, current_user)
      end
      rescue Exception => exception
        msg = exception.record.class.name + " id: " + exception.record.id.to_s + ": " + exception.message
        self.errors.add("Move:", msg)
        move_result = false
    end

    return move_result
  end
  
  def has_been_through_qc?
    not self.qc_state.blank?
  end

  def sanger_human_barcode
    if self.barcode
      return self.prefix + self.barcode.to_s + Barcode.calculate_checksum(self.prefix, self.barcode)
    else
      return nil
    end
  end

  def ean13_barcode
    if barcode && self.prefix
      return Barcode.calculate_barcode(self.prefix, self.barcode.to_i).to_s
    else
      return nil
    end
  end
  
  def set_external_release(state)
    update_external_release do 
      case 
      when state == 'failed'  then self.external_release = false
      when state == 'passed'  then self.external_release = true
      when state == 'pending' then self # Do nothing
      when state.nil?         then self # TODO: Ignore for the moment, correct later     
      when [ 'scanned_into_lab' ].include?(state.to_s) then self # TODO: Ignore for the moment, correct later
      else raise StandardError, "Invalid external release state #{state.inspect}"
      end
    end
  end
  
  def update_external_release(&block)
    external_release_nil_before = external_release.nil?
    yield
    self.save!
    self.events.create_external_release!(!external_release_nil_before) unless self.external_release.nil?
  end
  private :update_external_release

  def set_qc_state(state) 
    case state
    when 'fail'
      self.qc_state = "failed"
    when 'pass'
      self.qc_state = "passed"
    else
      self.qc_state = state
    end
    self.save
    self.set_external_release(self.qc_state) 
  end

  def self.find_by_human_barcode(barcode, location)
    data = Barcode.split_human_barcode(barcode)
    if data[0] == 'DN'
      plate = Plate.find_by_barcode(data[1])
      well = plate.find_well_by_name(location)
      return well if well 
    end
    raise ActiveRecord::RecordNotFound, "Couldn't find well with for #{barcode} #{location}"
  end

  def self.get_barcode_from_params(params)
    prefix = 'NT'
    asset = nil
    if _pre=params[:prefix]
      prefix = _pre
    else
      begin
        asset = Asset.find(params[:id])
        prefix = asset.prefix
      rescue
      end
    end
    if asset and asset.barcode
      barcode = Barcode.calculate_barcode(prefix, asset.barcode.to_i)
    else
      barcode = Barcode.calculate_barcode(prefix, params[:id].to_i)
    end

    barcode
  end

  def assign_relationships(parents, child)
    if parents.kind_of?(Array) && child.kind_of?(Asset)
      parents.each do |parent|
        parent.children.delete(child)
      end

      AssetLink.create_edge(self, child)

      parents.each do |parent|
        AssetLink.create_edge(parent, self)
      end
    end
  end

  def self.print_assets(assets, barcode_printer)
    printables = []
    assets.each do |asset|
      printables.push BarcodeLabel.new({ :number => asset.barcode, :study => asset.tube_name, :suffix => "", :prefix => asset.prefix })
    end
    begin
      unless printables.empty?
        barcode_printer.print printables, barcode_printer.name
      end
    rescue
      return false
    end

    true
  end

  # We accept not only an individual barcode but also an array of them.  This builds an appropriate
  # set of conditions that can find any one of these barcodes.  We map each of the individual barcodes
  # to their appropriate query conditions (as though they operated on their own) and then we join
  # them together with 'OR' to get the overall conditions.
  named_scope :with_machine_barcode, lambda { |*barcodes|
    query_details = barcodes.flatten.map do |source_barcode|
      barcode_number = Barcode.number_to_human(source_barcode)
      prefix_string  = Barcode.prefix_from_barcode(source_barcode)
      barcode_prefix = BarcodePrefix.find_by_prefix(prefix_string)

      if barcode_number.nil? or prefix_string.nil? or barcode_prefix.nil?
        { :query => 'FALSE' }
      else
        { :query => '(barcode=? AND barcode_prefix_id=?)', :conditions => [ barcode_number, barcode_prefix.id ] }
      end
    end.inject({ :query => [], :conditions => [] }) do |building, current|
      building.tap do
        building[:query]      << current[:query]
        building[:conditions] << current[:conditions]
      end
    end

    { :conditions => [ query_details[:query].join(' OR '), *query_details[:conditions].flatten.compact ] }
  }
  
  
  named_scope :source_assets_from_machine_barcode, lambda { |destination_barcode|
    destination_asset = find_from_machine_barcode(destination_barcode)
    if destination_asset
      source_asset_ids = destination_asset.parents.map(&:id)
      unless source_asset_ids.empty?
        { :conditions => ["id IN (?)",source_asset_ids ] }
      else
        { :conditions => 'FALSE' }
      end
    else
      { :conditions => 'FALSE' }
    end 
  }
  
  
  def self.find_from_machine_barcode(source_barcode)
    with_machine_barcode(source_barcode).first
  end
  
  def barcode_and_created_at_hash 
    return {} if barcode.blank?
    {
      :barcode    => generate_machine_barcode,
      :created_at => created_at
    }
  end
  
  def generate_machine_barcode
    "#{Barcode.calculate_barcode( barcode_prefix.prefix,barcode.to_i)}"
  end
  
  def external_release_text
    return "Unknown" if self.external_release.nil?
    return self.external_release? ? "Yes" : "No"
  end

  def add_parent(parent)
    return unless parent
    #should be self.parents << parent but that doesn't work
    
    self.save!
    parent.save!
    AssetLink.connect(parent, self)
  end

  def attach_tag(tag)
    return unless tag
    tag_instance = TagInstance.new(:tag => tag)
    self.parents << tag_instance
  end
  
  def requests_status(request_type)
   # get the most recent request (ignore previous runs)
    self.requests.sort_by{ |r| r.id }.select{ |request| request.request_type == request_type }.map{ |filtered_request| filtered_request.state }
  end

  def transfer(volume)
    volume = [volume.to_f, self.volume || 0].min
    raise VolumeError, "not enough volume left" if volume <=0

    #create new asset
    new_asset = self.class.new

    # copy usefull fields from parent
    new_asset.material = self.material
    new_asset.name = self.name

    new_asset.add_parent(self)

    # updating volume
    new_asset.volume = volume
    self.volume -= volume

    self.save!
    new_asset.save!

    return new_asset
  end

  def spiked_in_buffer
    return nil
  end
  
  def has_stock_asset?
    return false
  end
  
  def tags
    return []
  end
  
    
  def has_many_requests?
    Request.find_all_target_asset(self.id).size > 1
  end
  
  def is_a_resource
   self.resource == true
  end

  private
  def set_default_prefix
    if barcode_prefix.nil?
      self.barcode_prefix = BarcodePrefix.find_by_prefix(self.prefix)
    end
  end
  
end
