# A Type of robot
class Beckman < RobotVerification
  def expected_layout(batch, destination_plate_barcode)
    batch.beckman_layout_plate_barcodes(destination_plate_barcode)
  end
end
