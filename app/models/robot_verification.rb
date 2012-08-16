class RobotVerification
  def validate_barcode_params(barcode_hash)
    return yield("No barcodes specified")      if barcode_hash.nil?
    yield("Worksheet barcode invalid")         if barcode_hash[:batch_barcode].nil?             or not Batch.valid_barcode?(barcode_hash[:batch_barcode])
    yield("Tecan robot barcode invalid")       if barcode_hash[:robot_barcode].nil?             or not Robot.valid_barcode?(barcode_hash[:robot_barcode])
    yield("User barcode invalid")              if barcode_hash[:user_barcode].nil?              or not User.valid_barcode?(barcode_hash[:user_barcode])
    yield("Destination plate barcode invalid") if barcode_hash[:destination_plate_barcode].nil? or Plate.find_by_barcode(Barcode.number_to_human(barcode_hash[:destination_plate_barcode])).nil?
  end

  def expected_layout(batch, destination_plate_barcode)
    batch.tecan_layout_plate_barcodes(Barcode.number_to_human(destination_plate_barcode))
  end

  def valid_source_plates_on_robot?(beds, plates, robot, batch,all_expected_plate_layout)
    valid_plates_on_robot?(beds, plates, "SCRC", robot, batch, all_expected_plate_layout[1])
  end

  def valid_destination_plates_on_robot?(beds, plates, robot, batch, all_expected_plate_layout)
    valid_plates_on_robot?(beds, plates, "DEST", robot, batch, all_expected_plate_layout[0])
  end

  def valid_plates_on_robot?(beds, plates, bed_prefix, robot, batch, expected_plate_layout)
    return false if expected_plate_layout.blank?
    expected_plate_layout.each do |plate_barcode, bed_number|
      scanned_bed_barcode = Barcode.number_to_human(beds["#{bed_number}"])
      expected_bed_barcode = robot.robot_properties.find_by_key("#{bed_prefix}#{bed_number}")
      return false if expected_bed_barcode.nil?
      return false if scanned_bed_barcode != expected_bed_barcode.value
      return false if plates[plate_barcode] != plate_barcode
    end

    true
  end

  def valid_plate_locations?(params, batch, robot, expected_plate_layout)
    return false if ! valid_source_plates_on_robot?(params[:bed_barcodes],params[:plate_barcodes], robot,batch,expected_plate_layout)
    return false if ! valid_destination_plates_on_robot?(params[:destination_bed_barcodes],params[:destination_plate_barcodes], robot,batch,expected_plate_layout)

    true
  end

  def valid_submission?(params)
    destination_plate_barcode = params[:barcodes][:destination_plate_barcode]
    batch = Batch.find_by_id(params[:batch_id])
    robot = Robot.find_by_id(params[:robot_id])
    user = User.find_by_id(params[:user_id])
    return false if batch.nil? || user.nil? || robot.nil? || destination_plate_barcode.blank?

    expected_plate_layout = self.expected_layout(batch, destination_plate_barcode)

    if valid_plate_locations?(params, batch, robot, expected_plate_layout)
      batch.events.create(
        :message => I18n.t("bed_verification.layout.valid", :plate_barcode => destination_plate_barcode),
        :created_by => user.login)
    else
      batch.events.create(
        :message => I18n.t("bed_verification.layout.invalid", :plate_barcode => destination_plate_barcode),
        :created_by => user.login)
      return false
    end

    true
  end

  def set_plate_types(plate_types_params)
    plate_types_params.each do |plate_barcode, plate_type|
      next if plate_barcode.blank? || plate_type.blank?
      plate = Plate.with_machine_barcode(plate_barcode).first or raise "Unable to locate plate #{plate_barcode.inspect} for robot verification"
      plate.set_plate_type(plate_type)
    end
  end
end
