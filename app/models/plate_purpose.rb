class PlatePurpose < ActiveRecord::Base
  cattr_reader :per_page
  @@per_page = 500
  include Uuid::Uuidable

  has_many :plates #, :class_name => "Asset"
  acts_as_audited :on => [:destroy, :update]
  
  validates_format_of :name, :with => /^\w[\s\w._-]+\w$/i
  validates_presence_of :name
  validates_uniqueness_of :name, :message => "already in use"
  
  def self.render_class
    Api::PlatePurposeIO
  end
  
  def url_name
    "plate_purpose"
  end
  alias_method(:json_root, :url_name)

  def create_child_plates_from_scanned_plate(source_plate_barcode, current_user)
    plate = Asset.find_from_machine_barcode(source_plate_barcode) or raise ActiveRecord::RecordNotFound, "Could not find plate with machine barcode #{source_plate_barcode.inspect}"

    new_child_plates = []
    self.child_plate_purposes.each do |target_plate_purpose|
      child_plate = target_plate_purpose.target_plate_type.constantize.create_plate_with_barcode(plate)
      child_plate.plate_purpose = target_plate_purpose
      child_plate.size   = plate.size
      child_plate.location = plate.location
      child_plate.name   = "#{target_plate_purpose.name} #{child_plate.barcode}"
      child_plate.save!
      
      plate.events.create_plate!(target_plate_purpose, child_plate, current_user)

      if plate.study
        RequestFactory.create_assets_requests([child_plate.id], plate.study.id)
      end
      child_plate.delayed_stamp_samples_into_wells(plate.id)
      AssetLink.connect(plate,child_plate)
      new_child_plates << child_plate
    end

    new_child_plates
  end

  def child_plate_purposes
    [self]
  end

  def sort_plates_by_plate_purpose(plates)
    plates_by_plate_purpose = {}
    plates.each do |plate|
      unless plates_by_plate_purpose[plate.plate_purpose]
        plates_by_plate_purpose[plate.plate_purpose] = []
      end
      plates_by_plate_purpose[plate.plate_purpose] << plate
    end

    plates_by_plate_purpose
  end

  def create_barcode_labels_from_plates(plates)
    printables = []
    plates.each do |plate|
      if plate.parent
        parent_plate_barcode = plate.parent.barcode
      end

      printables.push BarcodeLabel.new({ :number => plate.barcode,
        :study  => plate.find_study_abbreviation_from_parent,
        :suffix => parent_plate_barcode,
        :prefix => plate.barcode_prefix.prefix })
    end

    printables
  end

  def create_plates_and_print_barcodes(source_plate_barcodes, barcode_printer,current_user)
    new_plates = create_plates(source_plate_barcodes, current_user)
    if new_plates.empty?
      return false
    end

    barcode_printer_name = barcode_printer.name
    sort_plates_by_plate_purpose(new_plates).each do |plate_purpose, plates|
      printables = create_barcode_labels_from_plates(plates)

      begin
        unless printables.empty?
          barcode_printer = BarcodePrinter.find_by_name(barcode_printer_name) or raise ActiveRecord::RecordNotFound, "Could not find barcode printer #{barcode_printer_name.inspect}"
          barcode_printer.print printables, barcode_printer.name, Plate.prefix, "long", "#{plate_purpose.name}", current_user.login
        end
      rescue => exception
        return false
      end
    end

    true
  end

  def create_plates(source_plate_barcodes, current_user)
    new_plates = []

    if source_plate_barcodes.blank?
      plate = Plate.create_plate_with_barcode
      plate.plate_purpose = self
      plate.save
      new_plates << plate
    else
      source_plate_barcodes.scan(/\d+/).each do |source_plate_barcode|
        child_plates = create_child_plates_from_scanned_plate(source_plate_barcode, current_user)
        if child_plates
          new_plates = new_plates | child_plates
        end
      end
    end

    new_plates
  end

  def target_plate_type
    if self.target_type.nil?
      return "Plate"
    end

    self.target_type
  end
  
  def self.stock_plate_purpose
    # IDs copied from SNP
    @stock_plate_purpose ||= PlatePurpose.find(2)
  end

  def create!(locations_to_wells)
    maps  = Hash[Map.where_description(locations_to_wells.keys).where_plate_size(96).all.map { |m| [m.description, m] }]
    wells = locations_to_wells.map { |l,w| w.tap { w.update_attributes!(:map => maps[l]) } }
    plates.create!(:wells => wells, :size => 96).tap do |plate|
      wells.each { |well| AssetLink.create_edge!(plate, well) }
    end
  end

  def create_empty_plate!
    plates.create!(:size => 96, :wells => Map.where_plate_size(96).all.map { |map| Well.new(:map => map) }).tap do |plate|
      plate.wells.each { |well| AssetLink.create_edge!(plate, well) }
    end
  end
end
