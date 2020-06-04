module Batch::TecanBehaviour
  def tecan_layout_plate_barcodes(target_barcode)
    data_object = generate_picking_data(target_barcode)
    dest_barcode_index = Sanger::Robots::Tecan::Generator.barcode_to_plate_index(data_object['destination'])
    source_barcode_index = Sanger::Robots::Tecan::Generator.source_barcode_to_plate_index(data_object['destination'])
    [dest_barcode_index, source_barcode_index]
  end

  def tecan_gwl_file_as_text(target_barcode, volume_required = 13)
    data_object = generate_picking_data(target_barcode, plate_type)
    Sanger::Robots::Tecan::Generator.mapping(data_object, volume_required.to_i)
  end
end
