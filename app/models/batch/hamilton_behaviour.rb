# Holds robot behaviour specific to the Hamilton
module Batch::HamiltonBehaviour
  def hamilton_csv_file_as_text(target_barcode)
    data_object = generate_picking_data(target_barcode)
    Sanger::Robots::Hamilton::Generator.mapping(data_object)
  end
end
