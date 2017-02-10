# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

module Batch::TecanBehaviour
  def validate_for_tecan(target_barcode)
    return false if user_id.nil?
    return false if requests.nil? || requests.size == 0

    requests.where(state: 'passed').find_each do |request|
      next unless request.target_asset.plate.barcode == target_barcode
      return false unless Well.find(request.asset).valid_well_on_plate
      return false unless Well.find(request.target_asset).valid_well_on_plate
    end
    true
  end

  def generate_tecan_data(target_barcode, override_plate_type = nil)
    # very slow
    # return nil unless validate_for_tecan(target_barcode)

    data_object = {
       'user' => user.login,
       'time' => Time.now,
       'source' => {},
       'destination' => {}
    }

    requests.includes([{ asset: :plate }, { target_asset: :plate }]).where(state: 'passed').find_each do |request|
      destination_barcode = request.target_asset.plate.barcode
      next unless destination_barcode == target_barcode

      full_source_barcode = request.asset.plate.barcode_for_tecan
      full_destination_barcode = request.target_asset.plate.barcode_for_tecan

      source_plate_name = request.asset.plate.stock_plate_name.tr('_', "\s")
      if override_plate_type
        source_plate_name = override_plate_type
      end

      if data_object['source'][full_source_barcode].nil?
        data_object['source'][full_source_barcode] = { 'name' => source_plate_name, 'plate_size' => request.asset.plate.size }
      end
      if data_object['destination'][full_destination_barcode].nil?
        data_object['destination'][full_destination_barcode] = {
          'name' => PlatePurpose.cherrypickable_default_type.first.name.tr('_', "\s"),
          'plate_size' => request.target_asset.plate.size
        }
      end
      if data_object['destination'][full_destination_barcode]['mapping'].nil?
        data_object['destination'][full_destination_barcode]['mapping'] = []
      end

      data_object['destination'][full_destination_barcode]['mapping'] << {
        'src_well'  => [full_source_barcode, request.asset.map.description],
        'dst_well'  => request.target_asset.map.description,
        'volume'    => (request.target_asset.get_picked_volume),
        'buffer_volume' => (request.target_asset.get_buffer_volume) }
    end

    data_object
  end

  def tecan_layout_plate_barcodes(target_barcode)
    data_object = generate_tecan_data(target_barcode)
    dest_barcode_index = Sanger::Robots::Tecan::Generator.barcode_to_plate_index(data_object['destination'])
    source_barcode_index = Sanger::Robots::Tecan::Generator.source_barcode_to_plate_index(data_object['destination'])
    [dest_barcode_index, source_barcode_index]
  end

  def tecan_gwl_file_as_text(target_barcode, volume_required = 13, plate_type = nil)
    data_object = generate_tecan_data(target_barcode, plate_type)
    Sanger::Robots::Tecan::Generator.mapping(data_object, volume_required.to_i)
  end

  def tecan_gwl_file(target_barcode, volume_required = 13)
    data_object = generate_tecan_data(target_barcode)
    gwl_data = Sanger::Robots::Tecan::Generator.mapping(data_object, volume_required.to_i)
    begin
      year = Time.now.year
      base_directory = "#{configatron.tecan_files_location}/#{year}"
      unless File.exist?(base_directory)
        FileUtils.mkdir base_directory
      end
      destinationbarcode = data_object['destination'].keys.join('_')
      gwl_file = File.new("#{base_directory}/#{destinationbarcode}_batch_#{id}.gwl", 'w')
      gwl_file.write(gwl_data)
      gwl_file.close
    rescue
      return false
    end
    true
  end
end
