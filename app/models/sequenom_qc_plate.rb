# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

class SequenomQcPlate < Plate
  DEFAULT_SIZE = 384
  self.per_page = 50

  attr_accessor :gender_check_bypass
  attr_accessor :plate_prefix
  attr_accessor :user_barcode

  validates_presence_of :name

  after_create :schedule_populate_wells_from_source_plates

  def source_plates
    return [] if parents.empty?
    source_barcodes.map do |plate_barcode|
      if plate_barcode.blank?
        nil
      else
        parents.detect { |plate| plate.barcode == plate_barcode }
      end
    end
  end

  def default_plate_size
    DEFAULT_SIZE
  end

  def populate_wells_from_source_plates
    source_plates.each_with_index do |plate, index|
      next if plate.nil?
      copy_source_wells!(plate, index)
    end
  end

  def schedule_populate_wells_from_source_plates
    Delayed::Job.enqueue SequenomWellPopulationJob.new(id)
  end

  def add_event_to_stock_plates(user_barcode)
    return false unless user_barcode_exist?(user_barcode)
    source_plates.each_with_index do |plate, _index|
      next if plate.nil?
      stock_plate = plate.stock_plate
      next if stock_plate.nil?
      stock_plate.events.create_sequenom_stamp!(User.lookup_by_barcode(user_barcode))
    end
    events.create_sequenom_plate!(User.lookup_by_barcode(user_barcode))
  end

  def compute_and_set_name(input_plate_names)
    # Only do this if this is a new_record or we'll
    # be doing it every time we pull it from the db.
    if new_record?

      input_plate_barcodes = input_plate_names.values.reject(&:blank?)
      # validate input_plate_names
      if do_gender_checks? and !source_plates_genders_valid?(input_plate_names)
        return false
      end

      return false unless at_least_one_source_plate?(input_plate_barcodes) and input_plates_exist?(input_plate_names)

      # Plate name e.g. QC1234_1235_1236_1237_20100801
      self.name = "#{plate_prefix}#{plate_number(input_plate_names)}#{plate_date}"
      self.barcode = PlateBarcode.create.barcode
    end
    true
  end

  def label_text_top
    "#{plate_label(2)} #{plate_label(3)}"
  end

  def label_text_bottom
    "#{plate_label(4)} #{plate_label(5)}"
  end

  def connect_input_plates(input_plate_barcodes)
    self.parents = Plate.with_machine_barcode(input_plate_barcodes)
  end

  protected

  def source_barcodes
    [label_match[2], label_match[3], label_match[4], label_match[5]]
  end

  def destination_map_based_on_source_row_col_and_quadrant(quadrant, row, col)
    row_offset, col_offset = quadrant_row_col_offset(quadrant)
    find_map_by_rowcol((row * 2) + row_offset, (col * 2) + col_offset)
  end

  # ---------------------------
  # | 0,0        | 0,1        |
  # | Quadrant 0 | Quadrant 1 |
  # |            |            |
  # ---------------------------
  # | 1,0        | 1,1        |
  # | Quadrant 2 | Quadrant 3 |
  # |            |            |
  # ---------------------------
  def quadrant_row_col_offset(quadrant)
    col_offset = case quadrant
                 when 1 then 1
                 when 3 then 1
                 else 0
                 end
    row_offset = case quadrant
                 when 2 then 1
                 when 3 then 1
                 else 0
                 end

    [row_offset, col_offset]
  end

  def copy_source_well_sequenom_plate!(plate, quadrant, row, col)
    source_well = plate.find_well_by_rowcol(row, col)
    return nil if source_well.nil?

    source_well.dup.tap do |cloned_well|
      cloned_well.plate    = self
      cloned_well.map      = destination_map_based_on_source_row_col_and_quadrant(quadrant, row, col)
      cloned_well.aliquots = source_well.aliquots.map(&:dup)
      cloned_well.save!

      # FIXME: This fix seems a bit dirty but it works
      # Adding source_wells directly to cloned_well parents is broken so have to
      # use the an explict call to AssetLink.connect instead. Unfortunately I
      # haven't been able to recreate the problem in testing. :(

      # cloned_well.parents << source_well
      AssetLink.create_edge!(source_well, cloned_well)
    end
  end

  def copy_source_wells!(plate, quadrant)
    (0..8).each do |row|
      (0..12).each do |col|
        copy_source_well_sequenom_plate!(plate, quadrant, row, col)
      end
    end
  end

  def input_plates_exist?(input_plate_names)
    input_plate_names.each do |_source_plate_number, source_plate_barcode|
      next if source_plate_barcode.blank?

      source_plate = Plate.find_from_machine_barcode(source_plate_barcode)

      if source_plate.nil?
        errors.add(:base, "Source Plate: #{source_plate_barcode} cannot be found")
        return false
      end
    end
    true
  end

  def at_least_one_source_plate?(input_plate_barcodes)
    if input_plate_barcodes.empty?
      errors.add(:base, 'At least one source input plate barcode must be entered.')
    else
      true
    end
  end

def user_barcode_exist?(user_barcode)
  if User.lookup_by_barcode(user_barcode).nil?
    errors.add(:base, 'Please scan your user barcode') if User.lookup_by_barcode(user_barcode).nil?
    false
  else
    true
  end
end

  def do_gender_checks?
    true unless gender_check_bypass
  end

  # Source plates should exist, obviously, and have contain at least one sample with a gender
  def source_plates_genders_valid?(input_plate_names)
    input_plate_names.each do |_source_plate_number, source_plate_barcode|
      next if source_plate_barcode.blank?

      source_plate = Plate.find_from_machine_barcode(source_plate_barcode)

      if source_plate.nil?
        errors.add(:base, "Source Plate: #{source_plate_barcode} cannot be found")
        return false
      end
      # Unless our source plates all contain some samples with gender then
      # add an error to say things went wrong.
      unless source_plate.contains_gendered_samples?
        errors.add(:base, "Failed to create Sequenom QC Plate - Source Plate: #{source_plate_barcode} lacks gender information")
        return false
      end
    end
    true
  end

  # Create a match object for the input plate names from this
  # sequenom plate's name.
  def label_match
    @label_match ||= name.match(/^([^\d]+)(\d+)?_(\d+)?_(\d+)?_(\d+)?_(\d+)$/)
  end

  # This is the date format used by show when the plate was created
  # E.g. 1st August 2010 => 20100801.
  def plate_date
    Time.now.strftime('%Y%m%d')
  end

  # Return the matching plates human barcode padded out to 8 charactors
  # or just 8 space charactors if there's no input plate that position.
  def plate_label(plate_number)
    (label_match[plate_number] || '').ljust(7, "\s")
  end

  # Should join the values of the input_plate_names hash using underscores,
  # to give a new plate name.
  #
  # The order is (plates are interlieved):
  #
  #   _______________________
  #  |           |           |
  #  |  Plate 1  |  Plate 2  |
  #  |   A1      |    A1     |
  #  |-----------|-----------|
  #  |           |           |
  #  |  Plate 3  |  Plate 4  |
  #  |    A1     |     A1    |
  #   _______________________

  #  ...to give "plate1_plate2_plate3_plate4"
  def plate_number(input_plate_names)
    input_plate_names.inject('') do |return_value, (_index, barcode)|
      human_plate_name = Barcode.number_to_human(barcode) || ''
      return_value << human_plate_name << '_'
    end
  end
end
