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
        named_scope :with_plate_purpose, lambda { |*purposes|
          { :conditions => { :plate_purpose_id => purposes.flatten.map(&:id) } }
        }
      end
    end

    # Delegate the change of state to our plate purpose.
    def transition_to(state, contents = nil)
      plate_purpose.transition_to(self, state, contents)
    end
  end

  include Relationship::Associations

  # The state of a plate is based on the transfer requests.
  def state_of(plate)
    plate.send(:state_from, plate.transfer_requests)
  end

  # Updates the state of the specified plate to the specified state.  The basic implementation does this by updating
  # all of the TransferRequest instances to the state specified.  If contents is blank then the change is assumed to 
  # relate to all wells of the plate, otherwise only the selected ones are updated.
  def transition_to(plate, state, contents = nil)
    contents ||= []
    plate.transfer_requests.each do |request|
      request.update_attributes!(:state => state) if contents.empty? or contents.include?(request.target_asset.map.description)
    end
  end

  def pool_wells(wells)
    _pool_wells(wells).all(:select => 'assets.*, submission_id AS pool_id').tap do |wells_with_pool|
      raise StandardError, "Cannot deal with a well in multiple pools" if wells_with_pool.group_by(&:id).any? { |_, multiple_pools| multiple_pools.uniq.size > 1 }
    end
  end

  def _pool_wells(wells)
    wells.pooled_as_target_by(TransferRequest)
  end
  private :_pool_wells

  include Api::PlatePurposeIO::Extensions
  cattr_reader :per_page
  @@per_page = 500
  include Uuid::Uuidable

  # There's a barcode printer type that has to be used to print the labels for this type of plate.
  belongs_to :barcode_printer_type

  def barcode_type
    barcode_printer_type.printer_type_id
  end

  has_many :plates #, :class_name => "Asset"
  acts_as_audited :on => [:destroy, :update]

  named_scope :considered_stock_plate, { :conditions => { :can_be_considered_a_stock_plate => true } }
  
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
      PrintBarcode::Label.new(
        :number => plate.barcode,
        :study  => plate.find_study_abbreviation_from_parent,
        :suffix => plate.parent.try(:barcode),
        :prefix => plate.barcode_prefix.prefix
      )
    end
  end

  def create_plates_and_print_barcodes(source_plate_barcodes, barcode_printer,current_user)
    new_plates = create_plates(source_plate_barcodes, current_user)
    return false if new_plates.empty?

    sort_plates_by_plate_purpose(new_plates).each do |plate_purpose, plates|
      printables = create_barcode_labels_from_plates(plates) or next
      barcode_printer.print_labels(printables, Plate.prefix, "long", "#{plate_purpose.name}", current_user.login)
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

  def create!(*args, &block)
    attributes          = args.extract_options!
    do_not_create_wells = !!args.first

    attributes[:size] ||= 96
    plates.create_with_barcode!(attributes, &block).tap do |plate|
      plate.wells.import(Map.where_plate_size(plate.size).in_reverse_row_major_order.all.map { |map| Well.new(:map => map) }) unless do_not_create_wells
    end
  end
end
