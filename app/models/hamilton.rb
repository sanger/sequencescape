# A Type of robot
class Hamilton < RobotVerification
  def expected_layout(batch, destination_plate_barcode)
    batch.hamilton_layout_plate_barcodes(destination_plate_barcode)
  end
end
