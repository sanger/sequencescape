module Batch::HamiltonBehaviour
  def hamilton_csv_file_as_text(target_barcode, plate_type = nil)
    data_object = generate_picking_data(target_barcode, plate_type)
    Sanger::Robots::Hamilton::Generator.mapping(data_object)
  end
end
