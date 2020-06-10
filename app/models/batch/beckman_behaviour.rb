# Holds robot behaviour specific to the Beckman
module Batch::BeckmanBehaviour
  def beckman_csv_file_as_text(target_barcode)
    data_object = generate_picking_data(target_barcode)
    Sanger::Robots::Beckman::Generator.mapping(data_object)
  end
end
