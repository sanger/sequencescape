# frozen_string_literal: true

# Builds the information about a cherrypick for a {Batch}
class Robot::PickData
  attr_reader :batch, :user, :target_barcode

  delegate :requests, to: :batch

  def initialize(batch, target_barcode, user: batch.user, max_beds: nil)
    @batch = batch
    @target_barcode = target_barcode
    @user = user
    @max_beds = max_beds
  end

  def picking_data
    @picking_data ||= generate_picking_data
  end

  def picking_data_list
    @picking_data_list ||= generate_picking_data_list
  end

  private

  def generate_picking_data
    data_object = {
      'user' => user.login,
      'time' => Time.zone.now,
      'source' => {},
      'destination' => {}
    }

    requests.includes([
      { asset: [{ plate: [:barcodes, :labware_type] }, :map] },
      { target_asset: [:map, :well_attribute, { plate: [:barcodes, :labware_type] }] }
    ])
            .passed
            .find_each do |request|
      # Note: source includes control wells/plates
      source_plate = request.asset.plate
      target_plate = request.target_asset.plate
      source_well = request.asset
      target_well = request.target_asset

      next unless target_plate.any_barcode_matching?(target_barcode)

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

    data_object
  end

  def generate_picking_data_list
    data_objects = {}
    source_barcode_to_pick_number = {}

    current_pick_size = lambda do
      data_objects[data_objects.size - 1]['source'].size
    end

    requests_for_destination_plate.find_each do |request|
      target_plate = request.target_asset.plate
      next unless target_plate.any_barcode_matching?(target_barcode)

      source_barcode = request.asset.plate.machine_barcode

      # if no max beds, default to all in one pick
      pick_to_use = 0 unless @max_beds

      # find if barcode already encountered
      pick_to_use = source_barcode_to_pick_number[source_barcode]

      unless pick_to_use
        if !data_objects.empty? && current_pick_size.call < @max_beds
          # use latest pick if hasn't exceed robot beds limit
          pick_to_use = data_objects.size - 1
        else
          # start new pick
          pick_to_use = data_objects.size
          data_objects[pick_to_use] = {
            'destination' => {},
            'source' => {},
            'time' => Time.zone.now,
            'user' => user.login
          }
        end
        source_barcode_to_pick_number[source_barcode] = pick_to_use
      end

      data_object = data_objects[pick_to_use]
      populate_data_object!(data_object, request)
    end

    data_objects
  end

  def requests_for_destination_plate
    requests.includes([
      { asset: [{ plate: [:barcodes, :labware_type] }, :map] },
      { target_asset: [:map, :well_attribute, { plate: [:barcodes, :labware_type] }] }
    ]).passed
  end

  def populate_data_object!(data_object, request)
    # Note: source includes control wells/plates
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
    plate_type = (plate.plate_type || PlateType.cherrypickable_default_type).tr('_', "\s")
    control = plate.pick_as_control?
    {
      'name' => plate_type,
      'plate_size' => plate.size,
      'control' => control
    }
  end

  def destination_plate_information(plate)
    plate_information(plate).tap do |info|
      info['mapping'] = []
    end
  end
end
