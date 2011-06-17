class Plate < Asset
  include Api::PlateIO::Extensions
  include ModelExtensions::Plate
  include LocationAssociation::Locatable
  include Transfer::Associations
  include PlatePurpose::Associations

  # Transfer requests into a plate are the requests leading into the wells of said plate.
  def transfer_requests
    # TODO: This should be 'has_many :transfer_requests, :finder_sql => ....' for efficiency
    wells.map { |well| well.requests_as_target.where_is_a?(TransferRequest).all }.flatten
  end

  # The iteration of a plate is defined as the number of times a plate of this type has been created
  # from it's parent.  It's not quite that simple: it's actually the index of it's transfer_as_destination
  # within the transfers_as_source of its parent.
  def iteration
    return nil if parent.nil?  # No parent means no iteration, not a 0 iteration.

    index_of_plate = parent.transfers_as_source.all.select do |p|
      p.destination.is_a?(Plate) and p.destination.plate_purpose == plate_purpose
    end.index(transfer_as_destination)

    index_of_plate.nil? ? nil : index_of_plate+1
  end

  contains :wells, :order => '`assets`.map_id ASC' do
    def located_at(location)
      super(proxy_owner, location)
    end

    # After importing wells we need to also create the AssetLink and WellAttribute information for them.
    def post_import(links_data)
      time_now = Time.now

      AssetLink.import([:direct, :count, :ancestor_id, :descendant_id], links_data.map { |c| [true,1,*c] }, :validate => false)
      WellAttribute.import([:well_id, :created_at, :updated_at], links_data.map { |c| [c.last, time_now, time_now] }, :validate => false, :timestamps => false)
    end

    # Walks the wells A1, B1, C1, ... A2, B2, C2, ... H12
    def walk_in_column_major_order(&block)
      locations_to_well = Hash[self.map { |well| [ well.map.description, well ] }]
      Map.walk_plate_in_column_major_order(proxy_owner.size) do |map, index|
        yield(locations_to_well[map.description], index)
      end
    end

    # Walks the wells A1, A2, ... B1, B2, ... H12
    def walk_in_row_major_order(&block)
      locations_to_well = Hash[self.map { |well| [ well.map.description, well ] }]
      Map.walk_plate_in_row_major_order(proxy_owner.size) do |map, index|
        yield(locations_to_well[map.description], index)
      end
    end
  end

  #has_many :wells, :as => :holder, :class_name => "Well"
  DEFAULT_SIZE = 96
  self.prefix = "DN"
  cattr_reader :per_page
  @@per_page = 50

  before_create :set_plate_name_and_size

  named_scope :qc_started_plates, { :select => "distinct assets.*",  :order => 'assets.id DESC',  :conditions => ["(events.family = 'create_dilution_plate_purpose' OR asset_audits.key = 'slf_receive_plates') AND plate_purpose_id = #{PlatePurpose.find_by_name('Stock Plate').id}" ], :joins => "LEFT OUTER JOIN `events` ON events.eventful_id = assets.id LEFT OUTER JOIN `asset_audits` ON asset_audits.asset_id = assets.id  " ,:include => [:events, :asset_audits] }

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
    description  = (?A+row).chr+"#{col+1}"
    Map.find_by_description_and_asset_size(description, size)
  end

  def find_well_by_map_description(description)
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

  # A plate has a sample with the specified name if any of its wells have that sample.
  def sample?(sample_name)
    self.wells.any? do |well|
      well.aliquots.any? { |aliquot| aliquot.sample.name == sample_name }
    end
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

  def self.source_plate_types
    ["ABgene_0765","ABgene_0800"]
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
    self.plate_purpose.can_be_considered_a_stock_plate?
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
    self.parent.try(:wells).try(:first).try(:study).try(:abbreviation)
  end

  def self.create_with_barcode!(*args, &block)
    attributes = args.extract_options!
    barcode    = args.first
    barcode    = nil if barcode.present? and find_by_barcode(barcode).present?
    barcode  ||= PlateBarcode.create.barcode
    create!(attributes.merge(:barcode => barcode), &block)
  end

  def self.plates_from_scanned_plate_barcodes(source_plate_barcodes)
    source_plate_barcodes.scan(/\d+/).map(&method(:find_from_machine_barcode))
  end

  def self.plates_from_scanned_plates_and_typed_plate_ids(source_plate_barcodes)
    scanned_plates = source_plate_barcodes.scan(/\d+/).map(&method(:find_from_machine_barcode))
    typed_plates   = source_plate_barcodes.scan(/\d+/).map(&method(:find_by_barcode))

    (scanned_plates | typed_plates).compact
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
    Map.where_description(positions).where_plate_size(self.size).all.map(&:description).sort == positions.sort
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
