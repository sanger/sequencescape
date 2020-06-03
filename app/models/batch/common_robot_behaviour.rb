# Common robot behaviour
module Batch::CommonRobotBehaviour
  def generate_picking_data(target_barcode, override_plate_type = nil)
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
            .where(state: 'passed')
            .find_each do |request|
      target_plate = request.target_asset.plate

      next unless target_plate.any_barcode_matching?(target_barcode)

      full_source_barcode = request.asset.plate.machine_barcode
      full_destination_barcode = request.target_asset.plate.machine_barcode

      if data_object['source'][full_source_barcode].nil?
        source_plate_type = override_plate_type.presence || request.asset.plate.plate_type.tr('_', "\s")
        data_object['source'][full_source_barcode] = { 'name' => source_plate_type, 'plate_size' => request.asset.plate.size }
      end

      if data_object['destination'][full_destination_barcode].nil?
        target_plate_type = (target_plate.plate_type || PlateType.cherrypickable_default_type).tr('_', "\s")
        data_object['destination'][full_destination_barcode] = {
          'name' => target_plate_type,
          'plate_size' => request.target_asset.plate.size
        }
      end
      if data_object['destination'][full_destination_barcode]['mapping'].nil?
        data_object['destination'][full_destination_barcode]['mapping'] = []
      end

      data_object['destination'][full_destination_barcode]['mapping'] << {
        'src_well' => [full_source_barcode, request.asset.map.description],
        'dst_well' => request.target_asset.map.description,
        'volume' => (request.target_asset.get_picked_volume),
        'buffer_volume' => (request.target_asset.get_buffer_volume)
      }
    end

    data_object
  end
end
