module Batch::TecanBehaviour
  def validate_for_tecan(target_barcode)
    return false if user_id.nil?
    return false if requests.nil? || requests.size == 0

    requests.find_all_by_state("passed").each do |request|
      next unless request.target_asset.plate.barcode == target_barcode
      return false unless Well.find(request.asset).valid_well_on_plate
      return false unless Well.find(request.target_asset).valid_well_on_plate
    end
    true
  end

  def generate_tecan_data(target_barcode, override_plate_type = nil)
    # very slow
    #return nil unless validate_for_tecan(target_barcode)
    data_object = {
       "user" => user.login ,
       "time" => Time.now,
       "source" => {},
       "destination" => {}
    }
    requests.find_all_by_state("passed").each do |request|
      source_barcode = request.asset.plate.barcode
      destination_barcode = request.target_asset.plate.barcode
      next unless destination_barcode == target_barcode

      source_plate_name = request.asset.plate.stock_plate_name
      if override_plate_type
        source_plate_name = override_plate_type
      end

      if data_object["source"][source_barcode].nil?
        data_object["source"][source_barcode]  = {"name" => source_plate_name, "plate_size" => request.asset.plate.size}
      end
      if data_object["destination"][destination_barcode].nil?
        data_object["destination"][destination_barcode] = {"name" => Plate::SOURCE_PLATE_TYPES.last, "plate_size" => request.target_asset.plate.size }
      end
      if data_object["destination"][destination_barcode]["mapping"].nil?
        data_object["destination"][destination_barcode]["mapping"] = []
      end

      data_object["destination"][destination_barcode]["mapping"] << {
        "src_well"  => [source_barcode, request.asset.map.description],
        "dst_well"  => request.target_asset.map.description,
        "volume"    => (request.target_asset.get_picked_volume)  }
    end

    data_object
  end

  def tecan_layout_plate_barcodes(target_barcode)
    data_object = generate_tecan_data(target_barcode)
    dest_barcode_index = Generator.barcode_to_plate_index(data_object["destination"])
    source_barcode_index = Generator.source_barcode_to_plate_index(data_object["destination"])
    [dest_barcode_index,source_barcode_index]
  end

  def tecan_gwl_file_as_text(target_barcode, volume_required = 13, plate_type = nil)
    data_object = generate_tecan_data(target_barcode, plate_type)
    Generator.mapping(data_object,  volume_required.to_i)
  end

  def tecan_gwl_file(target_barcode,volume_required=13)
    data_object = generate_tecan_data(target_barcode)
    gwl_data  = Generator.mapping(data_object,  volume_required.to_i)
    begin
      year= Time.now.year
      base_directory ="#{configatron.tecan_files_location}/#{year}"
      unless File.exists?(base_directory)
        FileUtils.mkdir base_directory
      end
      destinationbarcode =  data_object["destination"].keys.join("_")
      gwl_file = File.new("#{base_directory}/#{destinationbarcode}_batch_#{self.id}.gwl", "w")
      gwl_file.write(gwl_data)
      gwl_file.close
    rescue
      return false
    end
    true
  end
end
