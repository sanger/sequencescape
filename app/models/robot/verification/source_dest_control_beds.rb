# A Type of robot

# This class of verification is for robots where the source plates and control
# plates have distinct beds
class Robot::Verification::SourceDestControlBeds < Robot::Verification::Base
  def expected_layout(batch, destination_plate_barcode)
    data_object = batch.generate_picking_data(destination_plate_barcode)
    destination = data_object['destination']
    source = data_object['source']
    dest_barcode_index = Sanger::Robots::Hamilton::Generator.barcode_to_plate_index(destination)
    source_barcode_index = Sanger::Robots::Hamilton::Generator.source_barcode_to_plate_index(destination, source)
    control_barcode_index = Sanger::Robots::Hamilton::Generator.control_barcode_to_plate_index(destination, source)
    [dest_barcode_index, source_barcode_index, control_barcode_index]
  end

  def valid_plate_locations?(params, batch, robot, expected_plate_layout)
    return false unless super
    return false unless valid_control_plates_on_robot?(beds, plates, robot, batch, all_expected_plate_layout)

    true
  end

  def valid_control_plates_on_robot?(beds, plates, robot, batch, all_expected_plate_layout)
    valid_plates_on_robot?(beds, plates, 'CTRL', robot, batch, all_expected_plate_layout[2])
  end
end
