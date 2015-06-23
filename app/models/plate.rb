#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2013,2014,2015 Genome Research Ltd.
class Plate < Asset
  include Api::PlateIO::Extensions
  include ModelExtensions::Plate
  include LocationAssociation::Locatable
  include Transfer::Associations
  include Transfer::State::PlateState
  include PlatePurpose::Associations
  include Barcode::Barcodeable
  include Asset::Ownership::Owned
  include Plate::Iterations
  include Plate::FluidigmBehaviour

  extend QcFile::Associations
  has_qc_files
  # The default state for a plate comes from the plate purpose
  delegate :default_state, :to => :plate_purpose, :allow_nil => true
  def state
    plate_purpose.state_of(self)
  end

  def cherrypick_completed
    plate_purpose.cherrypick_completed(self)
  end

  # The type of the barcode is delegated to the plate purpose because that governs the number of wells
  delegate :barcode_type, :to => :plate_purpose, :allow_nil => true
  delegate :asset_shape, :to => :plate_purpose, :allow_nil => true
  delegate :supports_multiple_submissions?, :to => :plate_purpose
  delegate :fluidigm_barcode, :to => :plate_metadata

  validates_length_of :fluidigm_barcode, :is => 10, :allow_blank => true

  # Transfer requests into a plate are the requests leading into the wells of said plate.
  def transfer_requests
    wells.all(:include => :transfer_requests_as_target).map(&:transfer_requests_as_target).flatten
  end

  # About 10x faster than going through the wells
  def submission_ids
    @siat ||=  container_associations.find(
      :all,
      :select => 'DISTINCT requests.submission_id',
      :joins  => 'LEFT JOIN requests ON requests.target_asset_id = container_associations.content_id',
      :conditions => 'requests.submission_id IS NOT NULL'
    ).map(&:submission_id)
  end

  def submission_ids_as_source
    @sias ||= container_associations.find(
      :all,
      :select => 'DISTINCT requests.submission_id',
      :joins  => 'LEFT JOIN requests ON requests.asset_id = container_associations.content_id',
      :conditions => 'requests.submission_id IS NOT NULL'
    ).map(&:submission_id)
  end

  def all_submission_ids
    submission_ids_as_source.present? ?
      submission_ids_as_source :
      submission_ids
  end

  def self.derived_classes
    @derived_classes ||= [ self, *Class.subclasses_of(self) ].map(&:name)
  end

  def prefix
    self.barcode_prefix.try(:prefix) || self.class.prefix
  end

  def submissions
    s = Submission.find(:all,
      :select => 'DISTINCT submissions.*',
      :joins => [
        'INNER JOIN requests as reqp ON reqp.submission_id = submissions.id',
        'INNER JOIN container_associations AS caplp ON caplp.content_id = reqp.asset_id'
      ],
      :conditions => ['caplp.container_id = ?',self.id]
    )
    return s unless s.blank?
    Submission.find(:all,
      :select => 'DISTINCT submissions.*',
      :joins => [
        'INNER JOIN requests as reqp ON reqp.submission_id = submissions.id',
        'INNER JOIN container_associations AS caplp ON caplp.content_id = reqp.target_asset_id'
      ],
      :conditions => ['caplp.container_id = ?',self.id]
    )
  end

  class CommentsProxy

    attr_reader :plate

    def initialize(plate)
      @plate=plate
    end

    def comment_assn
      @asn||=Comment.for_plate(plate)
    end

    def method_missing(method,*args)
      comment_assn.send(method,*args)
    end

    ##
    # We add the comments to each submission to ensure that are available for all the requests.
    # At time of writing, submissions add comments to each request, so there are a lot of comments
    # getting created here. (The intent is to change this so requests are treated similarly to plates)
    def create!(options)
      plate.submissions.each {|s| s.add_comment(options[:description],options[:user]) }
      Comment.create!(options.merge(:commentable=>plate))
    end

    def count(*args)
      super(args,{:select=>'DISTINCT comments.description, IFNULL(comments.title,""), comments.user_id'})
    end

  end

  def comments
    @comments||=CommentsProxy.new(self)
  end

  def priority
    Submission.find(:first,
      :select => 'MAX(submissions.priority) AS priority',
      :joins => [
        'INNER JOIN requests as reqp ON reqp.submission_id = submissions.id',
        'INNER JOIN container_associations AS caplp ON caplp.content_id = reqp.asset_id'
      ],
      :conditions => ['caplp.container_id = ?',self.id]
    ).try(:priority)||Submission.find(:first,
      :select => 'MAX(submissions.priority) AS priority',
      :joins => [
        'INNER JOIN requests as reqp ON reqp.submission_id = submissions.id',
        'INNER JOIN container_associations AS caplp ON caplp.content_id = reqp.target_asset_id'
      ],
      :conditions => ['caplp.container_id = ?',self.id]
    ).try(:priority)||0
  end

  def study
    wells.first.try(:study)
  end

  def studies
    Study.find_by_sql([ %Q{
SELECT DISTINCT s.*
FROM container_associations c
INNER JOIN aliquots a ON a.receptacle_id=c.content_id
INNER JOIN studies s ON a.study_id=s.id
WHERE c.container_id=?
}, self.id ])
  end

  contains :wells do #, :order => '`assets`.map_id ASC' do
    def located_at(location)
      super(proxy_owner, location)
    end

    # After importing wells we need to also create the AssetLink and WellAttribute information for them.
    def post_import(links_data)
      time_now = Time.now
      links_data.each do |c|
        AssetLink.create!(
          :direct => true,
          #:count => 1, Huh?
          :ancestor_id => c.first,
          :descendant_id => c.last
          )
        WellAttribute.create!(
          :well_id => c.last,
          :created_at => time_now,
          :updated_at => time_now
        )
      end
    end
    private :post_import

    def post_connect(well)
#      AssetLink.create!(:ancestor => proxy_owner, :descendant => well)
    end
    private :post_connect

    def construct!
      Map.where_plate_size(proxy_owner.size).where_plate_shape(proxy_owner.asset_shape).in_row_major_order.map do |location|
        build(:map => location)
      end.tap do |wells|
        proxy_owner.save!
        AssetLink::Job.create(proxy_owner, wells)
      end
    end

    def map_from_locations
      {}.tap do |location_to_well|
        self.walk_in_column_major_order do |well, _|
          raise "Duplicated well at #{well.map.description}" if location_to_well.key?(well.map)
          location_to_well[well.map] = well
        end
      end
    end

    # Returns the wells with their pool identifier included
    def with_pool_id
      proxy_owner.plate_purpose.pool_wells(self)
    end

    # Yields each pool and the wells that are in it
    def walk_in_pools(&block)
      with_pool_id.group_by(&:pool_id).each(&block)
    end

    # Walks the wells A1, B1, C1, ... A2, B2, C2, ... H12
    def walk_in_column_major_order(&block)
      self.in_column_major_order.each { |well| yield(well, well.map.column_order) }
    end

    # Walks the wells A1, A2, ... B1, B2, ... H12
    def walk_in_row_major_order(&block)
      self.in_row_major_order.each { |well| yield(well, well.map.row_order) }
    end

    def in_preferred_order
      proxy_owner.plate_purpose.in_preferred_order(self)
    end
  end

  named_scope :include_wells_and_attributes, { :include => { :wells => [ :map, :well_attribute ] } }

  #has_many :wells, :as => :holder, :class_name => "Well"
  DEFAULT_SIZE = 96
  self.prefix = "DN"
  cattr_reader :per_page
  @@per_page = 50

  before_create :set_plate_name_and_size

  named_scope :qc_started_plates, lambda {
    {
      :select => "distinct assets.*",
      :order => 'assets.id DESC',
      :conditions => ["(events.family = 'create_dilution_plate_purpose' OR asset_audits.key = 'slf_receive_plates') AND plate_purpose_id = ?", PlatePurpose.find_by_name('Stock Plate') ],
      :joins => "LEFT OUTER JOIN `events` ON events.eventful_id = assets.id LEFT OUTER JOIN `asset_audits` ON asset_audits.asset_id = assets.id" ,
      :include => [:events, :asset_audits]
    }
  }

  named_scope :with_sample,    lambda { |sample|
    {
      :select => "distinct assets.*",
      :joins => "LEFT OUTER JOIN container_associations AS wscas ON wscas.container_id = assets.id
  LEFT JOIN assets AS wswells ON wswells.id = content_id
  LEFT JOIN aliquots AS wsaliquots ON wsaliquots.receptacle_id = wswells.id",
      :conditions => ["wsaliquots.sample_id IN(?)", Array(sample)]
    }
  }

  named_scope :with_requests, lambda { |requests|
    {
      :select     => "DISTINCT assets.*",
      :joins      => [
        "INNER JOIN container_associations AS wrca ON wrca.container_id = assets.id",
        "INNER JOIN requests AS wrr ON wrr.asset_id = wrca.content_id"
      ],
      :conditions => [
        'wrr.id IN (?)',
        requests.map(&:id)
      ]
    }
  }

  def wells_sorted_by_map_id
    wells.sorted
  end

  def wells_sorted_by(&block)
    wells.sort { |a, b| block.call(a) <=> block.call(b) }
  end

  def children_and_holded
    ( children | wells )
  end

  def create_child
    raise StandardError, "Kaboom! Don't use this method!"
    child = Plate.create({:size => self.size})
    self.children << child

    self.wells.each do |well|
      child.add_well Well.create({:map_id => well.map_id, :sample_id => well.sample_id})
    end
    child
  end
  deprecate :create_child

  def find_map_by_rowcol(row, col)
    # Count from 0
    description  = asset_shape.location_from_row_and_column(row,col+1,size)
    Map.find(:first,
             :conditions =>{
              :description    => description,
              :asset_size     => size,
              :asset_shape_id => asset_shape
             })
  end

  def find_well_by_rowcol(row, col)
    map = self.find_map_by_rowcol(row,col)
    return nil if map.nil?
    self.find_well_by_name(map.description)
  end

  def add_well_holder(well)
    children << well
    well.plate = self
  end

  def add_well(well, row=nil, col=nil)
    add_well_holder(well)
    if row
      well.map = find_map_by_rowcol(row, col)
    end
  end

  def add_well_by_map_description(well,map_description)
    add_well_holder(well)
    well.map = Map.find_by_description_and_asset_size(map_description,size)
    well.save!
  end

  def add_and_save_well(well, row=nil, col=nil)
    self.add_well(well, row, col)
    well.save!
  end

  def find_well_by_name(well_name)
    self.wells.position_name(well_name, self.size).first
  end
  alias :find_well_by_map_description :find_well_by_name

  def plate_header
    [""] + plate_columns
  end

  def plate_rows
    ("A".."#{(?A+height-1).chr}").to_a
  end

  def plate_columns
    (1..width).to_a
  end

  def get_plate_type
    if self.descriptor_value('Plate Type').nil?
      plate_type = self.get_external_value('plate_type_description')
      set_plate_type(plate_type)
    end
    self.descriptor_value('Plate Type')
  end

  def set_plate_type(result)
    self.add_descriptor(Descriptor.new({:name => "Plate Type", :value => result}))
    self.save
  end

  def stock_plate_name
    (self.get_plate_type == "Stock Plate" || self.get_plate_type.blank?) ? PlatePurpose.cherrypickable_as_source.first.name : self.get_plate_type
  end

  def details
    purpose.try(:name)||'Unknown plate purpose'
  end

  def control_well_exists?
    Request.into_by_id(well_ids).any? do |request|
      request.asset.plate.is_a?(ControlPlate)
    end
  end

  # A plate has a sample with the specified name if any of its wells have that sample.
  def sample?(sample_name)
    self.wells.any? do |well|
      well.aliquots.any? { |aliquot| aliquot.sample.name == sample_name }
    end
  end

  def get_storage_location
    plate_location = HashWithIndifferentAccess.new
    return {"storage_area" => "Control"} if self.is_a?(ControlPlate)
    return {} if self.barcode.blank?
    ['storage_area', 'storage_device', 'building_area', 'building'].each do |key|
      plate_location[key] = self.get_external_value(key)
    end
    plate_location
  end

  def barcode_for_tecan
    raise StandardError, 'Purpose is not valid' if plate_purpose.present? and not plate_purpose.valid?
    plate_purpose.present? ? send(:"#{plate_purpose.barcode_for_tecan}") : ean13_barcode
  end

  def infinium_barcode
    self.plate_metadata.infinium_barcode
  end

  def infinium_barcode=(barcode)
    self.plate_metadata.infinium_barcode = barcode
    self.plate_metadata.save!
  end

  def valid_infinium_barcode?(barcode)
    true
  end

  def self.create_from_rack_csv(file_location, plate_barcode)
    plate = self.create(:name => "Plate #{plate_barcode}", :barcode => plate_barcode, :size => 96)

    FasterCSV.foreach(file_location) do |row|
      map = Map.find_for_cell_location(row.first, plate.size)
      unless row.last.strip.blank?
        asset = Asset.find_by_two_dimensional_barcode(row.last.strip)
        unless asset.nil?
          well = plate.wells.create(:sample => asset.sample, :map_id => map.id)
          well.name = "#{asset} #{well.id}"
          well.save
          AssetLink.create_edge(asset, well)
        else
          well = plate.wells.create(:map_id => map.id)
        end
      else
        well = plate.wells.create(:map_id => map.id)
      end
    end
    plate
  end

  def submission_time(current_time)
    current_time.strftime("%Y-%m-%dT%H_%M_%SZ")
  end

  def self.create_plates_with_barcodes(params)
    begin
      params[:snp_plates].each do |index,plate_barcode_id|
        next if plate_barcode_id.blank?
        plate = Plate.create(:barcode => "#{plate_barcode_id}", :name => "Plate #{plate_barcode_id}", :size => DEFAULT_SIZE)
        storage_location = Location.find(params[:asset][:location_id])
        plate.location = storage_location
        plate.save!
      end
    rescue
      return false
    end

    true
  end

  def self.plate_ids_from_requests(requests)
    plate_ids = []
    requests.map do |request|
      next if request.asset.nil?
      next unless request.asset.is_a?(Well)
      next if request.asset.plate.nil?
      plate_ids << request.asset.plate.id
    end

    plate_ids.uniq
  end

  def plate_asset_group_name(current_time)
    if self.barcode
      self.barcode+"_asset_group_#{submission_time(current_time)}"
    else
      self.id+"_asset_group_#{submission_time(current_time)}"
    end
  end

  def create_plate_submission(project, study, user, current_time)
    LinearSubmission.build!(
      :study => study,
      :project => project,
      :workflow => genotyping_submission_workflow,
      :user => user,
      :assets => wells,
      :request_types => submission_workflow_request_type_ids(genotyping_submission_workflow)
    )
  end

  def submission_workflow_request_type_ids(submission_workflow)
    submission_workflow.request_types.map(&:id)
  end

  def genotyping_submission_workflow
    Submission::Workflow.find_by_key("microarray_genotyping")
  end

  def self.create_plates_submission(project, study, plates, user)
    return false if user.nil? || project.nil? || study.nil?
    current_time = Time.now

    project.save
    plates.each do |plate|
      plate.generate_plate_submission(project, study, user,current_time)
    end

    true
  end

  # Should return true if any samples on the plate contains gender information
  def contains_gendered_samples?
    wells.any? do |well|
      well.aliquots.any? { |aliquot| aliquot.sample.present? and not aliquot.sample.sample_metadata.gender.blank? }
    end
  end

  def generate_plate_submission(project, study, user, current_time)
    submission = self.create_plate_submission(project, study, user, current_time)
    if submission
      self.events.create!(:message => I18n.t('studies.submissions.plate.event.success', :barcode => self.barcode, :submission_id => submission.id), :created_by => user.login)
    else
      self.events.create!(:message => I18n.t('studies.submissions.plate.event.failed', :barcode => self.barcode), :created_by => user.login)
      study.errors.add("plate_barcode", "Couldnt create submission for plate #{plate_barcode}")
    end
  end

  def create_sample_tubes
    wells.map(&:create_child_sample_tube)
  end

  def create_sample_tubes_and_print_barcodes(barcode_printer,location = nil)
    sample_tubes = create_sample_tubes
    Asset.print_assets(sample_tubes, barcode_printer)
    if location
      location.set_locations(sample_tubes)
    end

    sample_tubes
  end

  def self.create_sample_tubes_asset_group_and_print_barcodes(plates, barcode_printer, location, study)
    return nil if plates.empty?
    plate_barcodes = plates.map{ |plate| plate.barcode}
    asset_group = AssetGroup.find_or_create_asset_group("#{plate_barcodes.join('-')} #{Time.now.to_formatted_s(:sortable)} ", study)
    plates.each do |plate|
      next if plate.wells.empty?
      asset_group.assets << plate.create_sample_tubes_and_print_barcodes(barcode_printer, location)
    end

    return nil if asset_group.assets.empty?
    asset_group.save!

    asset_group
  end

  def stock_plate?
    return true if self.plate_purpose.nil?
    self.plate_purpose.can_be_considered_a_stock_plate? && self.plate_purpose.attatched?(self)
  end

  def stock_plate
    @stock_plate ||= stock_plate? ? self : lookup_stock_plate
  end

  def lookup_stock_plate
    spp = PlatePurpose.find(:all,:conditions=>{:can_be_considered_a_stock_plate=>true})
    self.ancestors.first(:order => 'created_at DESC', :conditions => {:plate_purpose_id=>spp})
  end
  private :lookup_stock_plate

  def ancestor_of_purpose(ancestor_purpose_id)
    return self if self.plate_purpose_id == ancestor_purpose_id
    ancestors.first(:order => 'created_at DESC', :conditions => {:plate_purpose_id=>ancestor_purpose_id})
  end

  def child_dilution_plates_filtered_by_type(parent_model)
    self.children.select{ |p| p.is_a?(parent_model) }
  end

  def children_of_dilution_plates(parent_model, child_model)
    child_dilution_plates_filtered_by_type(parent_model).map{ |dilution_plate| dilution_plate.children.select{ |p| p.is_a?(child_model) } }.flatten.select{ |p| ! p.nil? }
  end

  def child_pico_assay_plates
    children_of_dilution_plates(PicoDilutionPlate, PicoAssayAPlate)
  end

  def child_gel_dilution_plates
    children_of_dilution_plates(WorkingDilutionPlate, GelDilutionPlate)
  end

  def child_sequenom_qc_plates
    children_of_dilution_plates(WorkingDilutionPlate, SequenomQcPlate)
  end

  def find_study_abbreviation_from_parent
    self.parent.try(:wells).try(:first).try(:study).try(:abbreviation)
  end

  def self.create_with_barcode!(*args, &block)
    attributes = args.extract_options!
    barcode    = args.first || attributes[:barcode]
    barcode    = nil if barcode.present? and find_by_barcode(barcode).present?
    barcode  ||= PlateBarcode.create.barcode
    create!(attributes.merge(:barcode => barcode), &block)
  end

  def self.plates_from_scanned_plate_barcodes(source_plate_barcodes)
    source_plate_barcodes.scan(/\d+/).map { |barcode| find_from_machine_barcode(barcode) }
  end

  #--
  # NOTE: I'm getting odd behaviour where '&method(:find_from_machine_barcode)' raises a SecurityError.  I haven't
  # been able to track down why, and it only happens under 'rake cucumber', so somewhere something is doing something
  # nasty.
  #++
  def self.plates_from_scanned_plates_and_typed_plate_ids(source_plate_barcodes)
    scanned_plates = source_plate_barcodes.scan(/\d+/).map { |v| find_from_machine_barcode(v) }
    typed_plates   = source_plate_barcodes.scan(/\d+/).map { |v| find_by_barcode(v) }

    (scanned_plates | typed_plates).compact
  end

  def number_of_blank_samples
    self.wells.with_blank_samples.count
  end

  def default_plate_size
    DEFAULT_SIZE
  end

  def move_study_sample(study_from, study_to, current_user)
    study_from.events.create(
      :message => "Plate #{self.id} was moved to Study #{study_to.id}",
      :created_by => current_user.login,
      :content => "Plate moved by #{current_user.login}",
      :of_interest_to => "administrators"
    )

    study_to.events.create(
      :message => "Plate #{self.id} was moved from Study #{study_from.id}",
      :created_by => current_user.login,
      :content => "Plate moved by #{current_user.login}",
      :of_interest_to => "administrators"
    )
  end

  def scored?
    wells.any? { |w| w.get_gel_pass }
  end

  def buffer_required?
    wells.any?(&:buffer_required?)
  end

  def valid_positions?(positions)
    unique_positions_on_plate, unique_positions_from_caller = Map.where_description(positions).where_plate_size(self.size).where_plate_shape(self.asset_shape).all.map(&:description).sort.uniq, positions.sort.uniq
    unique_positions_on_plate == unique_positions_from_caller
  end

  def name_for_label
    self.name
  end

  def set_plate_name_and_size
    self.name = "Plate #{barcode}" if self.name.blank?
    self.size = default_plate_size if self.size.nil?
    self.location = Location.find_by_name("Sample logistics freezer") if self.location_id.nil?
  end
  private :set_plate_name_and_size

  extend Metadata
  has_metadata do
    attribute(:infinium_barcode)
    attribute(:fluidigm_barcode)
  end

  def barcode_label_for_printing
    PrintBarcode::Label.new(
      :number => self.barcode,
      :study  => self.find_study_abbreviation_from_parent,
      :suffix => self.parent.try(:barcode),
      :prefix => self.barcode_prefix.prefix
    )
  end

  def height
    asset_shape.plate_height(size)
  end

  def width
    asset_shape.plate_width(size)
  end

  # This method returns a map from the wells on the plate to their stock well.
  def stock_wells
    # Optimisation: if the plate is a stock plate then it's wells are it's stock wells!
    return Hash[wells.with_pool_id.map { |w| [w,[w]] }] if stock_plate?
    Hash[wells.with_pool_id.map { |w| [w, w.stock_wells.in_column_major_order] }.reject { |_,v| v.empty? }].tap do |stock_wells_hash|
      raise "No stock plate associated with #{id}" if stock_wells_hash.empty?
    end
  end

  def convert_to(new_purpose)
    self.update_attributes!(:plate_purpose=>new_purpose)
  end

  def compatible_purposes
    PlatePurpose.compatible_with_purpose(self.purpose)
  end

  def update_concentrations_from(parser)
    ActiveRecord::Base.transaction do
      parser.each_well_and_parameters do |position,concentration,molarity|
        wells.include_map.detect {|w| w.map_description == position }.tap do |well|
          well.set_concentration(concentration)
          well.set_molarity(molarity)
          well.save!
        end
      end
    end
    true
  end

  # Barcode is stored as a string, jet in a number of places is treated as
  # a number. If we conver it before searching, things are faster!
  def find_by_barcode(barcode)
    super(barcode.to_s)
  end
end
