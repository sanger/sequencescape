class Plate::Creator < ActiveRecord::Base
  class PurposeRelationship < ActiveRecord::Base
    set_table_name('plate_creator_purposes')

    belongs_to :plate_purpose
    belongs_to :plate_creator, :class_name => 'Plate::Creator'
  end

  set_table_name('plate_creators')

  # These are the plate purposes that will be created when this creator is used.
  has_many :plate_creator_purposes, :class_name => 'Plate::Creator::PurposeRelationship', :dependent => :destroy, :foreign_key => :plate_creator_id
  has_many :plate_purposes, :through => :plate_creator_purposes

  # If there are no barcodes supplied then we use the plate purpose we represent
  belongs_to :plate_purpose

  # Executes the plate creation so that the appropriate child plates are built.
  def execute(source_plate_barcodes, barcode_printer, scanned_user)
    ActiveRecord::Base.transaction do
      new_plates = source_plate_barcodes.blank? ? [ self.plate_purpose.plates.create_with_barcode! ] : create_plates(source_plate_barcodes, scanned_user)
      return false if new_plates.empty?

      new_plates.group_by(&:plate_purpose).each do |plate_purpose, plates|
        # barcode_printer.print_labels(plates.map(&:barcode_label_for_printing), Plate.prefix, "long", plate_purpose.name.to_s, scanned_user.login)
      end

      true
    end
  end

  def create_plates(source_plate_barcodes, current_user)
    scanned_barcodes = source_plate_barcodes.scan(/\d+/)
    raise "Scanned plate barcodes in incorrect format: #{source_plate_barcodes.inspect}" if scanned_barcodes.blank?

    # NOTE: Plate barcodes are not unique within certain laboratories.  That means that we cannot do:
    #  plates = Plate.with_machine_barcode(*scanned_barcodes).all(:include => [ :location, { :wells => :aliquots } ])
    # Because then you get multiple matches.  So we take the first match, which is just not right.
    scanned_barcodes.map do |scanned|
      plate =
        Plate.with_machine_barcode(scanned).first(:include => [ :location, { :wells => :aliquots } ]) or
          raise ActiveRecord::RecordNotFound, "Could not find plate with machine barcode #{scanned.inspect}"

      create_child_plates_from(plate, current_user)
    end.flatten
  end
  private :create_plates

  def create_child_plates_from(plate, current_user)
    stock_well_picker = plate.plate_purpose.can_be_considered_a_stock_plate? ? lambda { |w| [w] } : lambda { |w| w.stock_wells }
    plate_purposes.map do |target_plate_purpose|
      target_plate_purpose.target_plate_type.constantize.create_with_barcode!(plate.barcode) do |child_plate|
        child_plate.plate_purpose = target_plate_purpose
        child_plate.size          = plate.size
        child_plate.location      = plate.location
        child_plate.name          = "#{target_plate_purpose.name} #{child_plate.barcode}"
      end.tap do |child_plate|
          child_plate.wells << plate.wells.map do |well|
            well.clone.tap do |child_well|
              child_well.aliquots = well.aliquots.map(&:clone)
              child_well.stock_wells.attach(stock_well_picker.call(well))
            end
          end
        AssetLink.create_edge!(plate, child_plate)
        plate.events.create_plate!(target_plate_purpose, child_plate, current_user)
      end
    end
  end
  private :create_child_plates_from
end
