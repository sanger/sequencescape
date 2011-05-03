class Plate < Asset
  include ModelExtensions::Plate
  include LocationAssociation::Locatable

  contains :wells
  #has_many :wells, :as => :holder, :class_name => "Well"
  DEFAULT_SIZE = 96
  self.prefix = "DN"
  cattr_reader :per_page
  @@per_page = 50

  # plate_purpose is the chip type to be used with this plate.
  belongs_to :plate_purpose

  before_create :set_plate_name_and_size

  named_scope :including_associations_for_json, { :include => [:uuid_object, :plate_metadata, :barcode_prefix, { :plate_purpose => :uuid_object } ] }
  named_scope :qc_started_plates, { :select => "distinct assets.*",  :order => 'assets.id DESC',  :conditions => ["(events.family = 'create_dilution_plate_purpose' OR asset_audits.key = 'slf_receive_plates') AND plate_purpose_id = #{PlatePurpose.find_by_name('Stock Plate').id}" ], :joins => "LEFT OUTER JOIN `events` ON events.eventful_id = assets.id LEFT OUTER JOIN `asset_audits` ON asset_audits.asset_id = assets.id  " ,:include => [:events, :asset_audits] }

  def url_name
    "plate"
  end
  alias_method(:json_root, :url_name)

  def wells_sorted_by_map_id
    wells.sorted
  end

  def wells_sorted_by(&block)
    wells.sort { |a, b| block.call(a) <=> block.call(b) }
  end

  def quarantine_combine(plates)
    raise  Exception, "I thought this function wasn't used. It is ?"
    # Need to fix the formula of this
    1.upto(4) do |quadrant|
      1.upto(96) do |map_id|
        puts "--#{map_id}--#{map_id+(96*quadrant)}--"
        well = self.children.find_by_map_id(map_id+(96*quadrant))
        well.parents << plates[quadrant-1].children.find_by_map_id(map_id)
      end
    end
  end
  
  def children_and_holded
    ( children | wells )
  end

  def create_child
    child = Plate.create({:size => self.size})
    self.children << child

    self.wells.each do |well|
      child.add_well Well.create({:map_id => well.map_id, :sample_id => well.sample_id})
    end
    child
  end

  def find_map_by_rowcol(row, col)
    description  = (?A+row).chr+"#{col+1}"
    Map.find_by_description_and_asset_size(description, size)
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

  def map_id_offset
    first_map = Map.find_by_asset_size(size, :order => 'id ASC')
    raise Exception, "No maps found for the plate size '#{size}'" unless first_map
    return first_map.id - 1 # - so 1 + offset = 0
  end

  # TODO:  move to ContainerAssociation module
  def import_wells(wells)
    #Plate.benchmark("import #{wells.size} wells") do
    # slow
    # This is a hack to get the id of the imported wells
    # we prefix all the name so we can found and reload the new created wells, by name
    # We then only update with the real one
    
    thread_name = "%.5d-" % $PID
    original_names = []
    Plate.benchmark("import tweaking name") do
    wells.each do |well|
      original_names << well.name
      well.name = "#{thread_name}#{well.name}"
    end
    end
    
    #Plate.benchmark("import importing #{wells.size}") do
      Well.import wells
    #end

    sub_wells = []
    Plate.benchmark("import reloading") do
      sub_wells = Well.find(:all, :conditions => ["name LIKE ?", "#{thread_name}%"], :select => "id, name")
      sub_wells.each do |sub_well|
        sub_well.name = sub_well.name[thread_name.size, -1]
      end
    end
    #Plate.benchmark("import renaming") do
      # we can skip the validation, hoping that its been already done and partially on the name
      # the fake name being already validated
      Well.import [:id, :name], sub_wells, :on_duplicate_key_update => [:name], :validate => false
    #end
    associations = sub_wells.map { |w| ContainerAssociation.new(:container_id => id, :content_id => w.id) }
    ContainerAssociation.import associations
    #end
  end

  def create_wells_with_samples(samples, count = 96)
    well_data = []

    self.size  = count
    offset = map_id_offset
    1.upto(count) do |i|
      well_data << Well.new(:plate => self, :map_id => i+offset, :sample => samples.shift)
    end

    import_wells(well_data)

    self.save
    self.reload
    self.create_well_attributes(self.wells)

    self.wells
  end

  def create_well_attributes(wells)
    well_attributes = []
    wells.each do |well|
      well_attributes << [well.id]
    end
    WellAttribute.import [:well_id], well_attributes
  end

  def find_well_by_name(well_name)
    self.wells.position_name(well_name, self.size).first
  end

  def plate_header
    rows = [""]
    if self.size == 384
      rows += (1..24).to_a
    else
      rows += (1..12).to_a
    end
    rows
  end

  def plate_rows
    if self.size == 384
      return ("A".."P").to_a
    else
      return ("A".."H").to_a
    end
  end

  def plate_columns
    if self.size == 384
      return (1..24).to_a
    else
      return (1..12).to_a
    end
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

  def control_well_exists?
    wells.each do |well|
      request = Request.find_by_target_asset_id(well.id)
      unless request.nil?
        source_well = request.asset
        if source_well.parent.is_a?(ControlPlate)
          return true
        end
      end
    end
    false
  end

  def stock_plate_name
    if self.get_plate_type == "Stock Plate" || self.get_plate_type.blank?
      return "ABgene_0765"
    end
    self.get_plate_type
  end

  def sample?(sample_name)
    self.wells.each do |well|
      next if well.sample.nil?
      next if well.sample.name.blank?
      if well.sample.name == sample_name
        return true
      end
    end
    false
  end

  def get_storage_location
    plate_location= HashWithIndifferentAccess.new
    return {"storage_area" => "Control"} if self.is_a?(ControlPlate)
    return {} if self.barcode.blank?
    ['storage_area', 'storage_device', 'building_area', 'building'].each do |key|
      plate_location[key] = self.get_external_value(key)
    end
    if plate_location.nil?
      return {}
    else
      plate_location
    end
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
    Submission.build!(
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

    project.enforce_quotas = false
    project.save
    plates.each do |plate|
      plate.generate_plate_submission(project, study, user,current_time)
    end
    # TODO: return an error if insufficient quota
    #project.enforce_quotas = true
    #project.save

    true
  end
  
  # Should return true if any samples on the plate contains gender information
  def contains_gendered_samples?
    genders_count = 0
    
    wells.each  do |well|
      next if well.sample.nil?
      # Does the sample in this well have a gender?
      genders_count += 1 if !well.sample.sample_metadata.gender.blank?
    end
    
    # So did we find any samples with a gender?
    genders_count > 0
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

  def self.source_plate_types
    ["ABgene_0765","ABgene_0800"]
  end

  def self.render_class
    Api::PlateIO
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
    if self.plate_purpose.nil? or (self.plate_purpose && self.plate_purpose.name == "Stock Plate")
      true
    else
      false
    end
  end

  def stock_plate
    @stock_plate ||= lookup_stock_plate
  end

  def lookup_stock_plate
    # TODO: correctly lookup stock plate via pico dilution from assay plate
    self.parents.each do |parent_plate|
      next unless parent_plate.is_a?(Plate)
      return parent_plate if parent_plate.stock_plate?

      if parent_plate.parents
        parent_plate.parents.each do |parent_parent_plate|
          next unless parent_parent_plate.is_a?(Plate)
          if parent_parent_plate.stock_plate?
            return parent_parent_plate
          end
        end
      end
    end

    nil
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
    if self.parent && self.parent.wells.first && self.parent.wells.first.study
      return self.parent.wells.first.study.abbreviation
    end

    nil
  end

  def self.create_plate_with_barcode(plate = nil)
    if plate && ! self.find_by_barcode(plate.barcode)
      self.create(:barcode => plate.barcode)
    else
      barcode = PlateBarcode.create.barcode
      self.create(:barcode => barcode)
    end
  end

  def self.plates_from_scanned_plate_barcodes(source_plate_barcodes)
    source_plate_barcodes.scan(/\d+/).map{ |raw_barcode| self.find_from_machine_barcode(raw_barcode) }
  end

  def self.plates_from_scanned_plates_and_typed_plate_ids(source_plate_barcodes)
    scanned_plates = source_plate_barcodes.scan(/\d+/).map{ |raw_barcode| self.find_from_machine_barcode(raw_barcode) }
    typed_plates = source_plate_barcodes.scan(/\d+/).map{ |barcode_number| self.find_by_barcode(barcode_number) }

    (scanned_plates | typed_plates).select{ |plates| ! plates.nil? }
  end

  def self.create_default_plates_and_print_barcodes(source_plate_barcodes, barcode_printer, current_user)
    return false if source_plate_barcodes.blank? || barcode_printer.blank?
    self.plates_from_scanned_plate_barcodes(source_plate_barcodes).each do |plate|
      plate.plate_purpose.create_plates_and_print_barcodes(plate.generate_machine_barcode, barcode_printer, current_user)
    end

    true
  end

  def number_of_blank_samples
    self.wells.with_blank_samples.count
  end

  def delayed_stamp_samples_into_wells(plate_id)
    return if self.wells.size > 0
    plate = Plate.find(plate_id)
    plate.wells.each do |well|
      cloned_well = well.clone
      cloned_well.plate = self
      cloned_well.save!
    end
  end
  #handle_asynchronously :delayed_stamp_samples_into_wells

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

  private
  def set_plate_name_and_size
    self.name = "Plate #{barcode}" if self.name.blank?
    self.size = default_plate_size if self.size.nil?
    self.location = Location.find_by_name("Sample logistics freezer") if self.location.nil?
  end



  extend Metadata
  has_metadata do
    attribute(:infinium_barcode)
  end
end
