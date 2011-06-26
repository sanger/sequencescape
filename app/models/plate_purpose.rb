class PlatePurpose < ActiveRecord::Base
  class Relationship < ActiveRecord::Base
    set_table_name('plate_purpose_relationships')
    belongs_to :parent, :class_name => 'PlatePurpose'
    belongs_to :child, :class_name => 'PlatePurpose'

    module Associations
      def self.included(base)
        base.class_eval do
          has_many :child_relationships, :class_name => 'PlatePurpose::Relationship', :foreign_key => :parent_id, :dependent => :destroy
          has_many :child_plate_purposes, :through => :child_relationships, :source => :child

          has_many :parent_relationships, :class_name => 'PlatePurpose::Relationship', :foreign_key => :child_id, :dependent => :destroy
          has_many :parent_plate_purposes, :through => :parent_relationships, :source => :parent
        end
      end
    end
  end

  module Associations
    def self.included(base)
      base.class_eval do
        belongs_to :plate_purpose
      end
    end

    # Delegate the change of state to our plate purpose.
    def transition_to(state)
      plate_purpose.transition_to(self, state)
    end
  end

  include Relationship::Associations

  # Updates the state of the specified plate to the specified state.  The basic implementation does this by updating
  # all of the TransferRequest instances to the state specified.
  def transition_to(plate, state)
    plate.transfer_requests.each do |request|
      request.update_attributes!(:state => state)
    end
  end

  include Api::PlatePurposeIO::Extensions
  cattr_reader :per_page
  @@per_page = 500
  include Uuid::Uuidable

  has_many :plates #, :class_name => "Asset"
  acts_as_audited :on => [:destroy, :update]
  
  validates_format_of :name, :with => /^\w[\s\w._-]+\w$/i
  validates_presence_of :name
  validates_uniqueness_of :name, :message => "already in use"

  def create_child_plates_from_scanned_plate(source_plate_barcode, current_user)
    plate = Asset.find_from_machine_barcode(source_plate_barcode) or raise ActiveRecord::RecordNotFound, "Could not find plate with machine barcode #{source_plate_barcode.inspect}"
    create_child_plates_from(plate, current_user)
  end

  def create_child_plates_from(plate, current_user)
    child_plate_purposes.map do |target_plate_purpose|
      target_plate_purpose.target_plate_type.constantize.create_with_barcode!(plate.barcode) do |child_plate|
        child_plate.plate_purpose = target_plate_purpose
        child_plate.size          = plate.size
        child_plate.location      = plate.location
        child_plate.name          = "#{target_plate_purpose.name} #{child_plate.barcode}"
      end.tap do |child_plate|
        plate.wells.each do |well|
          child_plate.wells << well.clone.tap do |child_well|
            child_well.aliquots = well.aliquots.map(&:clone)
          end
        end

        RequestFactory.create_assets_requests([child_plate.id], plate.study.id) if plate.study.present?
        AssetLink.create_edge!(plate, child_plate)

        plate.events.create_plate!(target_plate_purpose, child_plate, current_user)
      end
    end
  end

  def sort_plates_by_plate_purpose(plates)
    plates.inject(Hash.new { |h,k| h[k] = [] }) do |plates_by_plate_purpose, plate|
      plates_by_plate_purpose.tap { plates_by_plate_purpose[plate.plate_purpose] << plate }
    end
  end

  def create_barcode_labels_from_plates(plates)
    plates.map do |plate|
      BarcodeLabel.new(
        :number => plate.barcode,
        :study  => plate.find_study_abbreviation_from_parent,
        :suffix => plate.parent.try(:barcode),
        :prefix => plate.barcode_prefix.prefix
      )
    end
  end

  def create_plates_and_print_barcodes(source_plate_barcodes, barcode_printer,current_user)
    new_plates = create_plates(source_plate_barcodes, current_user)
    if new_plates.empty?
      return false
    end

    #TODO don't find again the printer by it's name, just use it
    barcode_printer_name = barcode_printer.name
    sort_plates_by_plate_purpose(new_plates).each do |plate_purpose, plates|
      printables = create_barcode_labels_from_plates(plates)

      begin
        unless printables.empty?
          barcode_printer = BarcodePrinter.find_by_name(barcode_printer_name) or raise ActiveRecord::RecordNotFound, "Could not find barcode printer #{barcode_printer_name.inspect}"
          barcode_printer.print_labels(printables, Plate.prefix, "long", "#{plate_purpose.name}", current_user.login)
        end
      rescue => exception
        return false
      end
    end

    true
  end

  def create_plates(source_plate_barcodes, current_user)
    return [ plates.create_with_barcode! ] if source_plate_barcodes.blank?

    source_plate_barcodes.scan(/\d+/).map do |source_plate_barcode|
      create_child_plates_from_scanned_plate(source_plate_barcode, current_user)
    end.flatten.compact
  end

  def target_plate_type
    self.target_type || 'Plate'
  end
  
  def self.stock_plate_purpose
    # IDs copied from SNP
    @stock_plate_purpose ||= PlatePurpose.find(2)
  end

  # TODO: For the moment I'm removing this but I need the code to remain whilst it's refactored.
  #
  # It was originally here for pipelines to create plates from pre-existing wells but I actually think that's the wrong
  # way for things to work.  I think that plates are created completely empty, and then transfers are made from one container
  # to the plate.  That's certainly how it feels for the pulldown pipeline.
#  def create!(locations_to_wells)
#    maps  = Hash[Map.where_description(locations_to_wells.keys).where_plate_size(96).all.map { |m| [m.description, m] }]
#    wells = locations_to_wells.map { |l,w| w.tap { w.update_attributes!(:map => maps[l]) } }
#    plates.create!(:wells => wells, :size => 96).tap do |plate|
#      wells.each { |well| AssetLink.create_edge!(plate, well) }
#    end
#  end

  def create!(*args, &block)
    attributes          = args.extract_options!
    do_not_create_wells = !!args.first

    attributes[:size] ||= 96
    plates.create_with_barcode!(attributes, &block).tap do |plate|
      plate.wells.import(Map.where_plate_size(plate.size).all.map { |map| Well.new(:map => map) }) unless do_not_create_wells
    end
  end
end
