# frozen_string_literal: true

# Builds the information about a cherrypick for a {Batch}
class Robot::PickData
  attr_reader :batch, :user

  delegate :requests, to: :batch

  #
  # Create a pick data object
  #
  # @param [Batch] batch The batch being picked
  # @param [User] user The user generating the file (defaults to batch owner)
  # @param [Integer] max_beds The maximum number of source plates in any one pick
  #
  def initialize(batch, user: batch.user, max_beds: nil)
    @batch = batch
    @user = user
    @max_beds = max_beds
    @picking_data_hash ||= Hash.new { |hash, barcode| hash[barcode] = generate_picking_data_hash(barcode) }
  end

  def picking_data_hash(target_barcode)
    @picking_data_hash[target_barcode]
  end

  private

  def default_type
    @default_type ||= PlateType.cherrypickable_default_type
  end

  # Given a list of requests it will sort them by:
  # - First group them by destination plate
  # - Second, inside that group sort them putting the controls (ie. those from the control plate) in the front
  # - Third, with the remaining requests, sort them in column order for that plate
  # rubocop:todo Metrics/PerceivedComplexity, Metrics/AbcSize
  def sorted_requests_for_destination_plate(requests_to_sort) # rubocop:todo Metrics/CyclomaticComplexity
    requests_to_sort.sort_by do |req|
      if req.target_asset&.map&.column_order
        [req.target_asset.plate.id, req.asset.plate&.pick_as_control? ? 0 : 1, req.target_asset.map.column_order]
      else
        [req.target_asset.plate.id, req.asset.plate&.pick_as_control? ? 0 : 1]
      end
    end
  end

  # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity

  # processes cherrypicking requests for a single batch and destination plate
  # if there are more source plates than the maximum capacity for the robot, splits it out into multiple picks
  # returns a hash of pick number (1-indexed) to data object containing info about source and destination plates
  # basic hash structure:
  # {
  #   1 => {
  #     'destination' => {},
  #     'source' => {},
  #     'time' => Time.zone.now,
  #     'user' => user.login
  #   },
  #   2 => { etc. }
  # }
  # see pick_data_spec.rb for the more detailed structure
  # rubocop:todo Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/MethodLength
  def generate_picking_data_hash(target_barcode, requests: requests_for_destination_plate)
    data_objects = {}
    source_barcode_to_pick_number = {}

    current_pick_size = lambda { data_objects[data_objects.size]['source'].size }

    sorted_requests_for_destination_plate(requests).each do |request|
      target_plate = request.target_asset.plate
      next unless target_plate.any_barcode_matching?(target_barcode)

      source_barcode = request.asset.plate.machine_barcode

      # find if there's already some data for this barcode
      pick_to_use = source_barcode_to_pick_number[source_barcode]

      unless pick_to_use
        # if no max beds, default to all in one pick
        pick_to_use =
          if @max_beds.nil?
            1
          elsif !data_objects.empty? && current_pick_size.call < @max_beds
            # use latest pick if hasn't exceeded robot beds limit
            data_objects.size
          else
            # start new pick
            data_objects.size + 1
          end
        source_barcode_to_pick_number[source_barcode] = pick_to_use
      end

      # initialize the data_object for this pick if it doesn't exist already
      data_objects[pick_to_use] ||= {
        'destination' => {},
        'source' => {},
        'time' => Time.zone.now,
        'user' => user.login
      }

      data_object = data_objects[pick_to_use]
      populate_data_object!(data_object, request)
    end

    data_objects
  end

  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/MethodLength

  def requests_for_destination_plate
    @requests_for_destination_plate ||=
      requests.includes(
        [
          { asset: [{ plate: %i[barcodes labware_type] }, :map] },
          { target_asset: [:map, :well_attribute, { plate: %i[barcodes labware_type] }] }
        ]
      ).passed
  end

  def populate_data_object!(data_object, request) # rubocop:todo Metrics/AbcSize
    # NOTE: source includes control wells/plates
    source_plate = request.asset.plate
    target_plate = request.target_asset.plate
    source_well = request.asset
    target_well = request.target_asset
    full_source_barcode = source_plate.machine_barcode
    full_destination_barcode = target_plate.machine_barcode

    data_object['source'][full_source_barcode] ||= plate_information(source_plate)
    data_object['destination'][full_destination_barcode] ||= destination_plate_information(target_plate)

    data_object['destination'][full_destination_barcode]['mapping'] << {
      'src_well' => [full_source_barcode, source_well.map_description],
      'dst_well' => target_well.map_description,
      'volume' => target_well.get_picked_volume,
      'buffer_volume' => target_well.get_buffer_volume
    }
  end

  def plate_information(plate)
    plate_type = (plate.plate_type || default_type).tr('_', "\s")
    control = plate.pick_as_control?
    { 'name' => plate_type, 'plate_size' => plate.size, 'control' => control }
  end

  def destination_plate_information(plate)
    plate_information(plate).tap { |info| info['mapping'] = [] }
  end
end
