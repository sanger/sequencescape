module Batch::TecanBehaviour
  def tecan_gwl_file_as_text(target_barcode, volume_required = 13)
    data_object = generate_picking_data(target_barcode)
    Sanger::Robots::Tecan::Generator.mapping(data_object, volume_required.to_i)
  end
end
