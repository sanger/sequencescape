# Holds robot behaviour specific to the Beckman
module Batch::BeckmanBehaviour
  # Currently unused
  def beckman_layout_plate_barcodes(target_barcode)
    data_object = generate_picking_data(target_barcode)
    destination = data_object['destination']
    source = data_object['source']
    dest_barcode_index = Sanger::Robots::Beckman::Generator.barcode_to_plate_index(destination)
    source_barcode_index = Sanger::Robots::Beckman::Generator.source_barcode_to_plate_index(destination, source)
    control_barcode_index = Sanger::Robots::Beckman::Generator.control_barcode_to_plate_index(destination, source)
    [dest_barcode_index, source_barcode_index, control_barcode_index]
  end

  def beckman_csv_file_as_text(target_barcode)
    data_object = generate_picking_data(target_barcode)
    Sanger::Robots::Beckman::Generator.mapping(data_object)
  end
end
