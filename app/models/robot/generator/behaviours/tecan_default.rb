# frozen_string_literal: true

# Module with the file generation functionality for Tecan robots
module Robot::Generator::Behaviours::TecanDefault

  def mapping(data_object: picking_data)
    raise ArgumentError, 'Data object not present for Tecan mapping' if data_object.nil?
    output_file_contents = [header(data_object)]

    buffer_data = buffers(data_object, total_volume)
    if buffer_data.present?
      output_file_contents << buffer_data
      output_file_contents << buffer_seperator
    end

    output_file_contents << dyn_mappings(data_object)
    output_file_contents << footer
    output_file_contents.join("\n").gsub(/\n\n/, "\n")
  end

  def sort_order
    :row_order
  end

  def header(data_object)
    "C;\nC; This file created by #{data_object['user']} on #{data_object['time']}\nC;"
  end

  def tecan_precision_value(value)
    value.to_f.round(configatron.tecan_precision)
  end

  # rubocop:todo Metrics/MethodLength
  def each_mapping(data_object) # rubocop:todo Metrics/AbcSize
    data_object['destination'].each do |dest_plate_barcode, plate_details|
      mapping_by_well = Hash.new { |h, i| h[i] = [] }
      plate_details['mapping'].each do |mapping|
        destination_position =
          Map::Coordinate.description_to_vertical_plate_position(mapping['dst_well'], plate_details['plate_size'])
        mapping_by_well[destination_position] << mapping
      end

      mapping_by_well.sort_by { |a| a[0] }.each do |_dest_position, mappings|
        mappings.each { |mapping| yield(mapping, dest_plate_barcode, plate_details) }
      end
    end
  end

  # rubocop:enable Metrics/MethodLength

  # rubocop:todo Metrics/MethodLength
  def dyn_mappings(data_object) # rubocop:todo Metrics/AbcSize
    dyn_mappings = ''
    each_mapping(data_object) do |mapping, dest_plate_barcode, plate_details|
      source_barcode = (mapping['src_well'][0]).to_s
      source_name = data_object['source'][(mapping['src_well'][0]).to_s]['name']
      source_position =
        Map::Coordinate.description_to_vertical_plate_position(
          mapping['src_well'][1],
          data_object['source'][(mapping['src_well'][0]).to_s]['plate_size']
        )
      destination_position =
        Map::Coordinate.description_to_vertical_plate_position(mapping['dst_well'], plate_details['plate_size'])
      temp =
        [
          "A;#{source_barcode};;#{source_name};#{source_position};;#{tecan_precision_value(mapping['volume'])}",
          "D;#{dest_plate_barcode};;#{plate_details['name']};#{destination_position};;#{tecan_precision_value(mapping['volume'])}",
          "W;\n"
        ].join("\n")
      dyn_mappings += temp
    end
    dyn_mappings
  end

  # rubocop:enable Metrics/MethodLength

  def buffer_seperator
    'C;'
  end

  def buffers(data_object, total_volume)
    buffer = []
    each_mapping(data_object) do |mapping, dest_plate_barcode, plate_details|
      next unless total_volume > mapping['volume']

      dest_name = data_object['destination'][dest_plate_barcode]['name']
      volume = mapping['buffer_volume']
      vert_map_id =
        Map::Coordinate.description_to_vertical_plate_position(mapping['dst_well'], plate_details['plate_size'])

      buffer << "A;#{buffer_info(vert_map_id)};;#{tecan_precision_value(volume)}\nD;#{dest_plate_barcode};;#{dest_name};#{vert_map_id};;#{tecan_precision_value(volume)}\nW;"
    end
    buffer.join("\n")
  end

  # rubocop:todo Metrics/PerceivedComplexity
  # rubocop:todo Metrics/AbcSize
  def footer # rubocop:todo Metrics/CyclomaticComplexity
    footer = "C;\n"
    source_barcode_index.sort_by { |a| a[1] }.each { |barcode, index| footer += "C; SCRC#{index} = #{barcode}\n" }
    if ctrl_barcode_index.present?
      footer = "C;\n"
      ctrl_barcode_index&.sort_by { |a| a[1] }&.each { |barcode, index| footer += "C; CTRL#{index} = #{barcode}\n" }
    end
    footer += "C;\n"
    dest_barcode_index.sort_by { |a| a[1] }.each { |barcode, index| footer += "C; DEST#{index} = #{barcode}\n" }
    footer
  end

    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/PerceivedComplexity
  end
