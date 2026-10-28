# frozen_string_literal: true

# Creates the payload's new labware. Each gets a stock purpose (Y26-283
# acceptance criteria), chosen by whether its samples have tags, which mark a
# library:
# - a plate: Stock Plate, or Library Stock Plate when its samples have tags
# - a tube: Standard sample, Standard library when one of its samples has
#   tags, or Standard MX when more than one has
# Its only barcode is the one it arrived with, in the external format.
class ApiOperation::Reception::Creation::LabwareFactory
  # The payload fields of the tag schemes; a sample with any of them has tags
  TAG_FIELDS = ApiOperation::Reception::Validation::SampleCheck::TAG_FIELDS

  # The purpose of a new plate whose samples have tags
  LIBRARY_PLATE_PURPOSE = 'Library Stock Plate'

  # @param new_labware [Array<ApiOperation::Reception::Payload::
  #   PayloadLabware>] the payload labware Sequencescape doesn't have
  def initialize(new_labware)
    @new_labware = new_labware
  end

  # Creates the labware, with the wells of plates.
  #
  # @return [Hash{ApiOperation::Reception::Payload::PayloadLabware =>
  #   Labware}] the new labware, by its payload labware
  def call
    @new_labware.index_with { create_labware(it) }
  end

  private

  def create_labware(payload_labware)
    if payload_labware.type == 'tube'
      create_tube(payload_labware)
    else
      create_plate(payload_labware)
    end
  end

  # As PlatePurpose#create! does, without its Sanger barcode from Baracoda
  def create_plate(payload_labware)
    purpose = plate_purpose(payload_labware)
    plate = purpose.target_class.new(purpose: purpose, size: purpose.size)
    build_barcode(plate, payload_labware)
    plate.save!
    plate.wells.construct!
    plate
  end

  def create_tube(payload_labware)
    purpose = tube_purpose(payload_labware)
    tube = purpose.target_class.new(purpose:)
    build_barcode(tube, payload_labware)
    tube.save!
    tube
  end

  # Gives the labware the barcode it arrived with before it is saved, so that
  # is its only barcode: a plate is named after it, and a sample tube doesn't
  # make itself a Sanger barcode
  def build_barcode(labware, payload_labware)
    labware.barcodes.build(format: :external, barcode: payload_labware.barcode)
  end

  def plate_purpose(payload_labware)
    if tagged_count(payload_labware).zero?
      purpose(:stock_plate) { PlatePurpose.stock_plate_purpose }
    else
      purpose(:library_plate) do
        PlatePurpose.find_by!(name: LIBRARY_PLATE_PURPOSE)
      end
    end
  end

  def tube_purpose(payload_labware)
    case tagged_count(payload_labware)
    when 0 then purpose(:sample_tube) { Tube::Purpose.standard_sample_tube }
    when 1 then purpose(:library_tube) { Tube::Purpose.standard_library_tube }
    else purpose(:mx_tube) { Tube::Purpose.standard_mx_tube }
    end
  end

  # Looks each purpose up once
  def purpose(key)
    @purposes ||= {}
    @purposes[key] ||= yield
  end

  # How many of the labware's samples have tags
  def tagged_count(payload_labware)
    payload_labware.receptacles.flat_map(&:samples).count do |payload_sample|
      payload_sample.fields.keys.intersect?(TAG_FIELDS)
    end
  end
end
