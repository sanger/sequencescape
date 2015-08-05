#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2013,2015 Genome Research Ltd.
class Plate::Creator < ActiveRecord::Base

  PlateCreationError = Class.new(StandardError)

  class PurposeRelationship < ActiveRecord::Base
    set_table_name('plate_creator_purposes')

    belongs_to :plate_purpose
    belongs_to :plate_creator, :class_name => 'Plate::Creator'

  end

  class ParentPurposeRelationship < ActiveRecord::Base
    set_table_name('plate_creator_parent_purposes')

    belongs_to :plate_purpose, :class_name => 'Purpose'
  end

  set_table_name('plate_creators')

  # These are the plate purposes that will be created when this creator is used.
  has_many :plate_creator_purposes, :class_name => 'Plate::Creator::PurposeRelationship', :dependent => :destroy, :foreign_key => :plate_creator_id
  has_many :plate_purposes, :through => :plate_creator_purposes

  has_many :parent_purpose_relationships, :class_name => 'Plate::Creator::ParentPurposeRelationship',:dependent => :destroy, :foreign_key => :plate_creator_id
  has_many :parent_plate_purposes, :through => :parent_purpose_relationships, :source => :plate_purpose

  # If there are no barcodes supplied then we use the plate purpose we represent
  belongs_to :plate_purpose

  serialize :valid_options

  def can_create_plates?(source_plate, plate_purposes)
    parent_plate_purposes.empty? || parent_plate_purposes.include?(source_plate.purpose)
  end

  # Executes the plate creation so that the appropriate child plates are built.
  def execute(source_plate_barcodes, barcode_printer, scanned_user, creation_parameters={})
    ActiveRecord::Base.transaction do
      new_plates = create_plates(source_plate_barcodes, scanned_user, creation_parameters)
      return false if new_plates.empty?
      new_plates.each do |child_plate|
        load_creation_parameters(child_plate, creation_parameters[:plate_creation_parameters])
      end
      new_plates.group_by(&:plate_purpose).each do |plate_purpose, plates|
        barcode_printer.print_labels(plates.map(&:barcode_label_for_printing), Plate.prefix, "long", plate_purpose.name.to_s, scanned_user.login)
      end
      true
    end
  end

  def create_plates(source_plate_barcodes, current_user, creation_parameters={})
    return [ self.plate_purpose.plates.create_with_barcode! ]  if source_plate_barcodes.blank?

    scanned_barcodes = source_plate_barcodes.scan(/\d+/)
    raise PlateCreationError, "Scanned plate barcodes in incorrect format: #{source_plate_barcodes.inspect}" if scanned_barcodes.blank?

    # NOTE: Plate barcodes are not unique within certain laboratories.  That means that we cannot do:
    #  plates = Plate.with_machine_barcode(*scanned_barcodes).all(:include => [ :location, { :wells => :aliquots } ])
    # Because then you get multiple matches.  So we take the first match, which is just not right.
    scanned_barcodes.map do |scanned|
      plate =
        Plate.with_machine_barcode(scanned).first(:include => [ :location, { :wells => :aliquots } ]) or
          raise ActiveRecord::RecordNotFound, "Could not find plate with machine barcode #{scanned.inspect}"
      unless can_create_plates?(plate, plate_purposes)
        raise PlateCreationError, "Scanned plate #{scanned} has a purpose #{plate.purpose.name} not valid for creating [#{self.plate_purposes.map(&:name).join(',')}]"
      end
      create_child_plates_from(plate, current_user, creation_parameters)
    end.flatten
  end
  private :create_plates

  def load_creation_parameters(obj, creation_parameters)
    obj.update_attributes!(creation_parameters) unless creation_parameters.nil?
  end
  private :load_creation_parameters

  def create_child_plates_from(plate, current_user, creation_parameters)
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
              load_creation_parameters(child_well, creation_parameters[:well_creation_parameters])
            end
          end
        AssetLink.create_edge!(plate, child_plate)
        plate.events.create_plate!(target_plate_purpose, child_plate, current_user)
      end
    end
  end
  private :create_child_plates_from
end
