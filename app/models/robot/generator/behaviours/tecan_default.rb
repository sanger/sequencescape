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

  def each_mapping(data_object)
    data_object['destination'].each do |dest_plate_barcode, plate_details|
      mapping_by_well =
        plate_details['mapping'].sort_by do |mapping|
          description_to_column_index(mapping['dst_well'], plate_details['plate_size'])
        end

      mapping_by_well.each { |mapping| yield(mapping, dest_plate_barcode, plate_details) }
    end
  end

  # rubocop:todo Metrics/MethodLength
  def dyn_mappings(data_object) # rubocop:todo Metrics/AbcSize
    dyn_mappings = +''
    each_mapping(data_object) do |mapping, dest_plate_barcode, dest_plate|
      source_barcode, source_well = mapping['src_well']
      source_name, source_size = data_object['source'][source_barcode.to_s].values_at('name', 'plate_size')

      source_position = description_to_column_index(source_well, source_size)
      destination_position = description_to_column_index(mapping['dst_well'], dest_plate['plate_size'])
      dyn_mappings << <<~TECAN
        A;#{source_barcode};;#{source_name};#{source_position};;#{tecan_precision_value(mapping['volume'])}
        D;#{dest_plate_barcode};;#{dest_plate['name']};#{destination_position};;#{tecan_precision_value(mapping['volume'])}
        W;
      TECAN
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
      vert_map_id = description_to_column_index(mapping['dst_well'], plate_details['plate_size'])

      buffer <<
        "A;#{buffer_info(vert_map_id)};;#{tecan_precision_value(volume)}\nD;#{dest_plate_barcode};;#{dest_name};#{vert_map_id};;#{tecan_precision_value(volume)}\nW;"
    end
    buffer.join("\n")
  end

  def footer
    footer = +"C;\n"
    sorted_source_plates.each { |barcode, index| footer << "C; SCRC#{index} = #{barcode}\n" }
    footer << "C;\n" if ctrl_barcode_index.present?
    sorted_control_plates.each { |barcode, index| footer << "C; CTRL#{index} = #{barcode}\n" }
    footer << "C;\n"
    sorted_destination_plates.each { |barcode, index| footer << "C; DEST#{index} = #{barcode}\n" }
    footer
  end

  def sorted_source_plates
    source_barcode_index.sort_by { |a| a[1] }
  end

  def sorted_control_plates
    ctrl_barcode_index&.sort_by { |a| a[1] } || []
  end

  def sorted_destination_plates
    dest_barcode_index.sort_by { |a| a[1] }
  end

  def description_to_column_index(well_name, plate_size)
    Map::Coordinate.description_to_vertical_plate_position(well_name, plate_size)
  end
end
