# frozen_string_literal: true

# Base class for handling bed verification for picking robots
class Robot::Verification::Base # rubocop:todo Metrics/ClassLength
  attr_reader :errors

  # rubocop:todo Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
  def validate_barcode_params(barcode_hash) # rubocop:todo Metrics/CyclomaticComplexity
    return yield('No barcodes specified') if barcode_hash.nil?

    if barcode_hash[:batch_barcode].blank? || !Batch.valid_barcode?(barcode_hash[:batch_barcode])
      yield('Worksheet barcode invalid')
    end
    if barcode_hash[:robot_barcode].blank? || !Robot.valid_barcode?(barcode_hash[:robot_barcode])
      yield('Robot barcode invalid')
    end
    if barcode_hash[:user_barcode].blank? || !User.find_with_barcode_or_swipecard_code(barcode_hash[:user_barcode])
      yield('User barcode invalid')
    end
    if barcode_hash[:destination_plate_barcode].blank? ||
         !Plate.with_barcode(barcode_hash[:destination_plate_barcode]).exists?
      yield('Destination plate barcode invalid')
    end
  end

  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity

  #
  # Returns an array of all pick numbers associated with the corresponding batch and plate_barcode
  # @note Added as I refactor the batches/_assets.html.erb page. Currently just wraps pick_number_to_expected_layout
  #       and as a result performs a lot of unnecessary work.
  #
  # @param [Batch] batch The Batch to get pick numbers for
  # @param [String] destination_plate_barcode The barcode of the destination plate
  # @param [Integer] max_beds The max_beds for plates on the robot
  #
  # @return [Array<String>] Array of pick numbers associated with the batch/plate
  #
  def pick_numbers(batch, destination_plate_barcode, max_beds)
    pick_number_to_expected_layout(batch, destination_plate_barcode, max_beds).keys
  end

  # Returns a hash of { pick_number => layout_data_object }, for a batch and a specific destination plate
  # pick_number is a sequential number, starting at 1
  # layout_data_object is an array of hashes: 1st Element: Hash of destination plate barcodes and their sort position
  #                                           2nd Element: Hash of source plate barcodes and their sort position
  #                                           3rd Element: Hash of control plate barcodes and their sort position when
  #                                                        appropriate. (nil otherwise)
  #     @example [{'DN3R'=>1},{'DN1S'=>1, 'DN2T'=>2}, {}]
  # There will only be more than one pick if the number of source plates exceed the max plates allowed on the robot
  # and therefore more than one pick is needed to transfer from all the wells onto the destination plate
  def pick_number_to_expected_layout(batch, destination_plate_barcode, max_beds)
    generate_picking_data_hash(batch, destination_plate_barcode, max_beds).transform_values do |data_object|
      layout_data_object(data_object)
    end
  end

  # Returns all pick information by destination_bed barcode
  # @example
  #  { 'DN3R' => {
  #   1 => [{'DN3R'=>1},{'DN1S'=>1, 'DN2T'=>2}, {}]
  # }}
  #
  # @param [Batch] batch The batch to get the pick-list for
  # @param [Integer] max_beds The max_beds for plates on the robot
  def all_picks(batch, max_beds)
    # @note No optimization yet.
    batch
      .output_plates
      .each_with_object({}) do |plate, store|
        store[plate.machine_barcode] = pick_number_to_expected_layout(batch, plate.machine_barcode, max_beds)
      end
  end

  # rubocop:todo Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
  def valid_submission?(params) # rubocop:todo Metrics/CyclomaticComplexity
    destination_plate_barcode = params[:barcodes][:destination_plate_barcode]
    batch = Batch.find_by(id: params[:batch_id])
    robot = Robot.find_by(id: params[:robot_id])
    user = User.find_by(id: params[:user_id])
    pick_number = params[:pick_number]

    @errors = []
    @errors << "Could not find batch #{params[:batch_id]}" if batch.nil?
    @errors << 'Could not find robot' if robot.nil?
    @errors << 'Could not find user' if user.nil?
    @errors << 'No destination barcode specified' if destination_plate_barcode.blank?
    @errors << 'Could not determine pick number' if pick_number.blank?
    return false unless @errors.empty?

    expected_plate_layout = robot.pick_number_to_expected_layout(batch, destination_plate_barcode)[pick_number.to_i]

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

  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity

  def record_plate_types(plate_types_params)
    plate_types_params.each do |plate_barcode, plate_type|
      next if plate_barcode.blank? || plate_type.blank?

      plate = Plate.with_barcode(plate_barcode).first or
        raise "Unable to locate plate #{plate_barcode.inspect} for robot verification"
      plate.plate_type = plate_type
      plate.save!
    end
  end

  private

  #
  # Returns a hash of plates to indexes sorted by destination well to make sure
  # the plates are put the right way round for the robot
  #
  # @param [Hash] destinations The destination attribute of the data object generated by
  #                            {Batch::CommonRobotBehaviour.source_barcode_to_plate_index}
  # @yield [String] barcode The barcode of the plate to make a decision about. Return true from
  #                         the block to include the plate, false to filter it.
  # @return [Hash] Hash of plate barcodes mapped to their bed index
  #
  def filter_barcode_to_plate_index(destinations)
    destinations.each_with_object({}) do |(destination_barcode, destination_info), all_barcodes|
      mapping_sorted = sort_mapping_by_destination_well(destination_barcode, destination_info['mapping'])
      mapping_sorted.each do |map_well|
        barcode, _well = map_well['src_well']
        next unless yield barcode if block_given?
        all_barcodes[barcode] ||= all_barcodes.length + 1
      end
    end
  end

  def sort_mapping_by_destination_well(plate_barcode, mapping)
    # query relevant 'map' records based on asset shape id & asset size, then sort by row order
    # return the original mapping if the Plate cannot be found using the barcode - for instance, if this is coming from
    # stock_stamper.rb
    plate = Plate.find_by_barcode(plate_barcode)
    return mapping if plate.nil?

    relevant_map_records_by_description = plate.maps.index_by(&:description)

    mapping.sort_by do |a|
      map_record_description = a['dst_well']
      relevant_map_records_by_description[map_record_description].send(sort_order)
    end
  end

  # Returns a hash of barcodes to indexes used for ordering plates to beds for the worksheet
  def barcode_to_plate_index(plates)
    plates
      .each_with_object({})
      .with_index { |(plate, barcodes_to_indexes), index| barcodes_to_indexes[plate[0]] = index + 1 }
  end

  def generate_picking_data_hash(batch, destination_plate_barcode, max_beds)
    cached_pick_data(batch, max_beds).picking_data_hash(destination_plate_barcode)
  end

  def valid_plate_locations?(params, batch, robot, expected_plate_layout) # rubocop:todo Metrics/MethodLength
    unless valid_source_plates_on_robot?(
      params[:bed_barcodes],
      params[:plate_barcodes],
      robot,
      batch,
      expected_plate_layout
    )
      return false
    end
    unless valid_destination_plates_on_robot?(
      params[:destination_bed_barcodes],
      params[:destination_plate_barcodes],
      robot,
      batch,
      expected_plate_layout
    )
      return false
    end

    true
  end

  def valid_source_plates_on_robot?(beds, plates, robot, batch, all_expected_plate_layout)
    valid_plates_on_robot?(beds, plates, 'SCRC', robot, batch, all_expected_plate_layout[1])
  end

  def valid_destination_plates_on_robot?(beds, plates, robot, batch, all_expected_plate_layout)
    valid_plates_on_robot?(beds, plates, 'DEST', robot, batch, all_expected_plate_layout[0])
  end

  # rubocop:todo Metrics/ParameterLists
  def valid_plates_on_robot?(beds, plates, bed_prefix, robot, _batch, expected_plate_layout)
    # rubocop:enable Metrics/ParameterLists
    return false if expected_plate_layout.blank?

    expected_plate_layout.each do |plate_barcode, sort_number|
      scanned_bed_barcode = Barcode.number_to_human(beds[sort_number.to_s].strip)
      expected_bed_barcode = robot.robot_properties.find_by!(key: "#{bed_prefix}#{sort_number}")
      return false if expected_bed_barcode.nil?
      return false if scanned_bed_barcode != expected_bed_barcode.value
      return false if plates[plate_barcode]&.strip != plate_barcode
    end

    true
  end

  def cached_pick_data(batch, max_beds)
    @cached_pick_data ||= {}
    @cached_pick_data[[batch, max_beds]] ||= Robot::PickData.new(batch, max_beds:)
  end
end
