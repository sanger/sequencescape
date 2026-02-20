# frozen_string_literal: true

# Module with the file generation functionality for Tecan robots
module Robot::Generator::Behaviours::TecanDefault # rubocop:disable Metrics/ModuleLength
  def mapping(data_object: picking_data)
    raise ArgumentError, 'Data object not present for Tecan mapping' if data_object.nil?

    output_file_contents = [header(data_object)]

    buffer_data = buffers(data_object)
    if buffer_data.present?
      output_file_contents << buffer_data
      output_file_contents << buffer_separator
    end

    output_file_contents << dyn_mappings(data_object)
    output_file_contents << footer
    output_file_contents.join("\n").gsub("\n\n", "\n")
  end

  def sort_order
    :row_order
  end

  def header(data_object)
    <<~HEADER
      C;
      C; This file created by #{data_object['user']} on #{data_object['time']}
      C;
    HEADER
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

  # Adds a Comment command between the buffer and sample addition steps.
  #
  # @return [String] the buffer separator string
  def buffer_separator
    'C;'
  end

  def buffers(data_object) # rubocop:disable Metrics/AbcSize
    data_object = data_object_for_buffers(data_object)
    buffer = []
    each_mapping(data_object) do |mapping, dest_plate_barcode, plate_details|
      # src_well is checked to distinguish between buffer for sample wells
      # and buffer for empty wells.
      next if mapping.key?('src_well') && total_volume <= mapping['volume']

      dest_name = data_object['destination'][dest_plate_barcode]['name']
      volume = mapping['buffer_volume']
      vert_map_id = description_to_column_index(mapping['dst_well'], plate_details['plate_size'])

      buffer << <<~TECAN
        A;#{buffer_info(vert_map_id)};;#{tecan_precision_value(volume)}
        D;#{dest_plate_barcode};;#{dest_name};#{vert_map_id};;#{tecan_precision_value(volume)}
        W;
      TECAN
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

  def column_index_to_description(index, plate_size)
    Map::Coordinate.vertical_plate_position_to_description(index, plate_size)
  end

  # Returns a new data object with buffer entries added for empty destination
  # wells, if the option is enabled; otherwise returns the original data object.
  # Only the fields used by the buffer steps are added to the new data object.
  # @param data_object [Hash] the original data object
  # @return [Hash] the new data object with buffer entries for empty wells,
  #   or the original data object if the option is not enabled
  # @example input data_object
  #  {"destination" =>
  #   {"SQPD-9101" =>
  #     {"name" => "ABgene 0765",
  #      "plate_size" => 96,
  #      "control" => false,
  #      "mapping" =>
  #       [{"src_well" => ["SQPD-9089", "A1"], "dst_well" => "A1", "volume" => 100.0, "buffer_volume" => 0.0},
  #        {"src_well" => ["SQPD-9089", "A2"], "dst_well" => "B1", "volume" => 100.0, "buffer_volume" => 0.0}]},
  #  "source" =>
  #   {"SQPD-9089" => {"name" => "ABgene 0800", "plate_size" => 96, "control" => false},
  #    "SQPD-9090" => {"name" => "ABgene 0800", "plate_size" => 96, "control" => false}},
  #  "time" => Thu, 19 Feb 2026 15:20:20.785717000 GMT +00:00,
  #  "user" => "admin"}
  #
  # @example output data_object
  #  {"destination" =>
  #   {"SQPD-9101" =>
  #     {"name" => "ABgene 0765",
  #      "plate_size" => 96,
  #      "control" => false,
  #      "mapping" =>
  #       [{"src_well" => ["SQPD-9089", "A1"], "dst_well" => "A1", "volume" => 100.0, "buffer_volume" => 0.0},
  #        {"src_well" => ["SQPD-9089", "A2"], "dst_well" => "B1", "volume" => 100.0, "buffer_volume" => 0.0},
  #        {"dst_well" => "C1", "buffer_volume" => 120.0}]},
  #        {"dst_well" => "D1", "buffer_volume" => 120.0}]},
  #        ...
  #        ]},
  #     }
  #   }
  def data_object_for_buffers(data_object) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity
    buffer_volume_for_empty_wells = @batch&.buffer_volume_for_empty_wells
    return data_object unless buffer_volume_for_empty_wells

    obj = { 'destination' => {} }
    data_object['destination'].each do |dest_plate_barcode, plate_details|
      plate = Plate.find_by_barcode(dest_plate_barcode)
      plate_size = plate_details['plate_size']
      # Initialise the destination section
      obj['destination'][dest_plate_barcode] = {
        'name' => plate_details['name'],
        'plate_size' => plate_size
      }
      # Create a hash of column index to the existing mapping entries
      index_to_mapping = plate_details['mapping'].index_by do |entry|
        description_to_column_index(entry['dst_well'], plate_size)
      end

      # Loop through the column order and generate new mapping entries
      # Add existing mappings if present and skip non-empty wells in case it is partial plate.
      mapping = []
      (1..plate_size).each do |index|
        # Add existing mapping if present for this column index.
        if index_to_mapping.key?(index)
          mapping << index_to_mapping[index]
          next
        end

        # Check if the destination well empty, in case of partial plate.
        dst_well = column_index_to_description(index, plate_size) # A1, B1, etc.
        well = plate.find_well_by_name(dst_well) # Well object or nil
        next if well.present? && !well.empty? # Skip non-empty wells

        # Add buffer for empty well
        mapping << {
          'dst_well' => dst_well,
          'buffer_volume' => buffer_volume_for_empty_wells
        }
      end
      obj['destination'][dest_plate_barcode]['mapping'] = mapping
    end
    obj
  end
end
