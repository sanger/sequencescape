# Common methods for robot file generators
module CommonFileGenerator
  # Returns a hash of barcodes to indexes used for ordering plates to beds for the worksheet
  def barcode_to_plate_index(plates)
    plates.each_with_object({}).with_index do |(plate, barcodes_to_indexes), index|
      barcodes_to_indexes[plate[0]] = index + 1
    end
  end

  # Returns a hash of plates to indexes sorted by destination well to make sure
  # the plates are put the right way round for the robot
  # e.g. for Tecan 'SCRC1' goes into the 1st row of the fluidigm chip, and 'SCRC2' into the 2nd
  def source_barcode_to_plate_index(destination)
    all_barcodes = []
    destination.each do |plate_id, plate_info|
      mapping_sorted = sort_mapping_by_destination_well(plate_id, plate_info['mapping'])
      mapping_sorted.each do |map_well|
        well = map_well['src_well']
        all_barcodes << well[0]
      end
    end
    all_barcodes.uniq.each_with_object({}).with_index do |(plate, plates_to_indexes), index|
      plates_to_indexes[plate] = index + 1
    end
  end

  def sort_mapping_by_destination_well(plate_id, mapping)
    # query relevant 'map' records based on asset shape id & asset size, then sort by row order
    # return the original mapping if the Plate cannot be found using the barcode - for instance, if this is coming from stock_stamper.rb
    plate = Plate.find_by_barcode(plate_id)
    return mapping if plate.nil?

    purpose = Purpose.find(plate.plate_purpose_id)

    relevant_map_records = Map.where(asset_shape_id: purpose.asset_shape_id, asset_size: plate.size)
    relevant_map_records_by_description = {}
    relevant_map_records.each { |map_record| relevant_map_records_by_description[map_record.description] = map_record }

    mapping.sort_by do |a|
      map_record_description = a['dst_well']
      relevant_map_records_by_description[map_record_description].row_order
    end
  end
end
