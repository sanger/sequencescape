# frozen_string_literal: true

# Taked barcodes and locations and returns matching assets
# eg
# DN123456P:A1,A2,A3 (Wells A1,A2,A3)
# DN123456P:1,2,3 (Columns 1,2,3)
# DN123456P:A,B (Rows A,B)
# DN123456P (Entire Plate)
# Imported from SubmissionCreator with minor adaptations to support tubes. Could
# do with refactoring and performance improvements
class Asset::Finder
  InvalidInputException = Class.new(StandardError)
  attr_reader :barcodes_wells, :processed_barcodes

  def initialize(barcode_locations)
    @barcodes_wells = barcode_locations.map { |bc_well| bc_well.split(':') }
  end

  def resolve
    barcodes_wells.flat_map do |labware_barcode, well_locations|
      labware = Labware.find_by_barcode(labware_barcode)
      raise InvalidInputException, "No labware found for barcode #{labware_barcode}." if labware.nil?

      well_array = (well_locations || '').split(',').map(&:strip).compact_blank

      labware.respond_to?(:wells) ? find_wells_in_array(labware, well_array) : labware
    end
  end

  # rubocop:todo Metrics/MethodLength, Metrics/AbcSize
  def find_wells_in_array(plate, well_array) # rubocop:todo Metrics/CyclomaticComplexity
    return plate.wells.in_column_major_order.with_aliquots.distinct if well_array.empty?

    well_array.flat_map do |map_description|
      case map_description
      when /^[a-z,A-Z][0-9]+$/
        # A well
        well = plate.find_well_by_name(map_description)
        if well.nil? || well.aliquots.empty?
          raise InvalidInputException, "Well #{map_description} on #{plate.human_barcode} does not exist or is empty."
        end

        well
      when /^[a-z,A-Z]$/
        # A row
        plate.wells.with_aliquots.in_plate_row(map_description, plate.size).distinct
      when /^[0-9]+$/
        # A column
        plate.wells.with_aliquots.in_plate_column(map_description, plate.size).distinct
      else
        raise InvalidInputException, "#{map_description} is not a valid well location"
      end
    end
  end

  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def barcodes
    barcodes_wells.map(&:first).uniq
  end
end
