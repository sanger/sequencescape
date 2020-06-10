# frozen_string_literal: true

require_dependency 'robot/verification'

# Base class for handling bed verification for picking robots
class Robot::Verification::Base
  attr_reader :errors

  def validate_barcode_params(barcode_hash)
    return yield('No barcodes specified')      if barcode_hash.nil?

    yield('Worksheet barcode invalid')         if barcode_hash[:batch_barcode].blank?             || !Batch.valid_barcode?(barcode_hash[:batch_barcode])
    yield('Tecan robot barcode invalid')       if barcode_hash[:robot_barcode].blank?             || !Robot.valid_barcode?(barcode_hash[:robot_barcode])
    yield('User barcode invalid')              if barcode_hash[:user_barcode].blank?              || !User.find_with_barcode_or_swipecard_code(barcode_hash[:user_barcode])
    yield('Destination plate barcode invalid') if barcode_hash[:destination_plate_barcode].blank? || !Plate.with_barcode(barcode_hash[:destination_plate_barcode]).exists?
  end

  def expected_layout(batch, destination_plate_barcode)
    data_object = batch.generate_picking_data(destination_plate_barcode)
    dest_barcode_index = Sanger::Robots::Tecan::Generator.barcode_to_plate_index(data_object['destination'])
    source_barcode_index = Sanger::Robots::Tecan::Generator.source_barcode_to_plate_index(data_object['destination'])
    [dest_barcode_index, source_barcode_index]
  end

  def valid_submission?(params)
    destination_plate_barcode = params[:barcodes][:destination_plate_barcode]
    batch = Batch.find_by(id: params[:batch_id])
    robot = Robot.find_by(id: params[:robot_id])
    user = User.find_by(id: params[:user_id])

    @errors = []
    @errors << "Could not find batch #{params[:batch_id]}" if batch.nil?
    @eerors << 'Could not find robot' if robot.nil?
    @errors << 'Could not find user' if user.nil?
    @errors << 'No destination barcode specified' if destination_plate_barcode.blank?
    return false unless @errors.empty?

    expected_plate_layout = expected_layout(batch, destination_plate_barcode)

    if valid_plate_locations?(params, batch, robot, expected_plate_layout)
      batch.events.create(
        message: I18n.t('bed_verification.layout.valid', plate_barcode: destination_plate_barcode),
        created_by: user.login
      )
    else
      batch.events.create(
        message: I18n.t('bed_verification.layout.invalid', plate_barcode: destination_plate_barcode),
        created_by: user.login
      )
      @errors << 'Bed layout invalid'
      return false
    end

    true
  end

  def record_plate_types(plate_types_params)
    plate_types_params.each do |plate_barcode, plate_type|
      next if plate_barcode.blank? || plate_type.blank?

      plate = Plate.with_barcode(plate_barcode).first or raise "Unable to locate plate #{plate_barcode.inspect} for robot verification"
      plate.plate_type = plate_type
      plate.save!
    end
  end

  private

  def valid_plate_locations?(params, batch, robot, expected_plate_layout)
    return false unless valid_source_plates_on_robot?(params[:bed_barcodes], params[:plate_barcodes], robot, batch, expected_plate_layout)
    return false unless valid_destination_plates_on_robot?(params[:destination_bed_barcodes], params[:destination_plate_barcodes], robot, batch, expected_plate_layout)

    true
  end

  def valid_source_plates_on_robot?(beds, plates, robot, batch, all_expected_plate_layout)
    valid_plates_on_robot?(beds, plates, 'SCRC', robot, batch, all_expected_plate_layout[1])
  end

  def valid_destination_plates_on_robot?(beds, plates, robot, batch, all_expected_plate_layout)
    valid_plates_on_robot?(beds, plates, 'DEST', robot, batch, all_expected_plate_layout[0])
  end

  def valid_plates_on_robot?(beds, plates, bed_prefix, robot, _batch, expected_plate_layout)
    return false if expected_plate_layout.blank?

    expected_plate_layout.each do |plate_barcode, bed_number|
      scanned_bed_barcode = Barcode.number_to_human(beds[bed_number.to_s].strip)
      expected_bed_barcode = robot.robot_properties.find_by!(key: "#{bed_prefix}#{bed_number}")
      return false if expected_bed_barcode.nil?
      return false if scanned_bed_barcode != expected_bed_barcode.value
      return false if plates[plate_barcode]&.strip != plate_barcode
    end

    true
  end
end
