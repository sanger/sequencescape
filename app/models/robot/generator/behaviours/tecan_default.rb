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
          Map::Coordinate.well_description_to_by_column_map_index(mapping['dst_well'], plate_details['plate_size'])
        end

      mapping_by_well.each { |mapping| yield(mapping, dest_plate_barcode, plate_details) }
    end
  end

  def dyn_mappings(data_object) # rubocop:todo Metrics/AbcSize
    dyn_mappings = +''
    each_mapping(data_object) do |mapping, dest_plate_barcode, dest_plate|
      source_barcode, source_well = mapping['src_well']
      source_name, source_size = data_object['source'][source_barcode.to_s].values_at('name', 'plate_size')

      source_position = Map::Coordinate.well_description_to_by_column_map_index(source_well, source_size)
      destination_position = Map::Coordinate.well_description_to_by_column_map_index(mapping['dst_well'],
                                                                                     dest_plate['plate_size'])

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

  def buffers(data_object)
    data_object = data_object_for_buffers(data_object)
    buffer = []
    each_mapping(data_object) do |mapping, dest_plate_barcode, plate_details|
      next if skip_buffer_entry?(mapping)

      buffer << buffer_entry(mapping, dest_plate_barcode, plate_details, data_object)
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

  # Returns a new data object with buffer entries added for empty destination
  # wells, if the option is enabled; otherwise returns the original data object.
  # NB. Only the fields used by the buffer steps are added to the new data object,
  # we cut out parts we don't need like the control flag and source plate details.
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
  #      "mapping" =>
  #       [{"src_well" => ["SQPD-9089", "A1"], "dst_well" => "A1", "volume" => 100.0, "buffer_volume" => 0.0},
  #        {"src_well" => ["SQPD-9089", "A2"], "dst_well" => "B1", "volume" => 100.0, "buffer_volume" => 0.0},
  #        {"dst_well" => "C1", "buffer_volume" => 120.0}]},
  #        {"dst_well" => "D1", "buffer_volume" => 120.0}]},
  #        ...
  #        ]},
  #     }
  #   }
  def data_object_for_buffers(data_object)
    buffer_volume_for_empty_wells = @batch&.buffer_volume_for_empty_wells
    return data_object unless buffer_volume_for_empty_wells

    obj = { 'destination' => {} }
    data_object['destination'].each do |dest_plate_barcode, plate_details|
      obj['destination'][dest_plate_barcode] =
        plate_mapping_for_buffers(dest_plate_barcode, plate_details, buffer_volume_for_empty_wells)
    end
    obj
  end

  private

  # Builds a destination plate mapping with buffer entries for empty wells if required.
  #
  # @param dest_plate_barcode [String] The barcode of the destination plate
  # @param plate_details [Hash] The details of the destination plate
  # @param buffer_volume_for_empty_wells [Float] Buffer volume to add for empty wells
  # @return [Hash] Plate mapping with buffer entries for empty wells
  def plate_mapping_for_buffers(dest_plate_barcode, plate_details, buffer_volume_for_empty_wells)
    plate = Plate.find_by_barcode(dest_plate_barcode)
    plate_size = plate_details['plate_size']
    # TODO: {PlateTemplate} fetch plate template assigned to batch here, use it to determine empty wells for buffer addition
    # TODO: {PlateTemplate} method parameters into opts hash and pass to build_buffer_mapping instead of individual parameters
    mapping = build_buffer_mapping(plate, plate_details, plate_size, buffer_volume_for_empty_wells)
    {
      'name' => plate_details['name'],
      'plate_size' => plate_size,
      'mapping' => mapping
    }
  end

  # Builds the mapping array for a plate, including buffer entries for empty wells.
  #
  # @param plate [Plate] The destination plate object
  # @param plate_details [Hash] The details of the destination plate
  # @param plate_size [Integer] The size of the plate (number of wells)
  # @param buffer_volume_for_empty_wells [Float] Buffer volume to add for empty wells
  # @return [Array<Hash>] Array of mapping and buffer entries
  def build_buffer_mapping(plate, plate_details, plate_size, buffer_volume_for_empty_wells)
    index_to_mapping = plate_details['mapping'].index_by { |entry| Map::Coordinate.well_description_to_by_column_map_index(entry['dst_well'], plate_size) }
    opts = {
      index_to_mapping:,
      plate:,
      plate_size:,
      buffer_volume_for_empty_wells:
    }
    (1..plate_size).each_with_object([]) do |index, mapping|
      mapping_or_buffer_entry(mapping, opts.merge(index:))
    end
  end

  # Appends either a mapping entry or a buffer entry for the given well index.
  #
  # @param mapping [Array<Hash>] The mapping array being built
  # @param opts [Hash] Options including :index_to_mapping, :plate, :index, :plate_size, :buffer_volume_for_empty_wells
  # @return [void]
  def mapping_or_buffer_entry(mapping, opts)
    if opts[:index_to_mapping].key?(opts[:index])
      mapping << opts[:index_to_mapping][opts[:index]]
    else
      buffer_entry = buffer_mapping_for_empty_well(opts[:plate], opts[:index], opts[:plate_size],
                                                   opts[:buffer_volume_for_empty_wells])
      mapping << buffer_entry if buffer_entry
    end
  end

  # Returns a buffer entry for an empty well, or nil if the well is not empty.
  #
  # @param plate [Plate] The destination plate object
  # @param index [Integer] The well index (by column order)
  # @param plate_size [Integer] The size of the plate
  # @param buffer_volume_for_empty_wells [Float] Buffer volume to add
  # @return [Hash, nil] Buffer entry hash or nil if well is not empty
  def buffer_mapping_for_empty_well(plate, index, plate_size, buffer_volume_for_empty_wells)
    dst_well = Map::Coordinate.by_column_map_index_to_well_description(index, plate_size)
    well = plate.find_well_by_name(dst_well)

    # If the well exists and not empty, we skip adding a buffer entry for it.
    return nil if well.present? && !well.empty?

    # Check if we have a plate template that says the well should be left empty.
    template_id = @batch&.plate_template_for_buffer_addition
    template = PlateTemplate.find(template_id) if template_id.present?

    # return if this well should remain empty according to the template
    template_well = template.find_well_by_name(dst_well) if template.present?
    return if template_well.present?

    # else set the buffer volume for this empty well
    { 'dst_well' => dst_well, 'buffer_volume' => buffer_volume_for_empty_wells }
  end

  # Determines if a buffer entry should be skipped for a mapping.
  #
  # @param mapping [Hash] The mapping entry
  # @return [Boolean] True if the buffer entry should be skipped
  def skip_buffer_entry?(mapping)
    mapping.key?('src_well') && total_volume <= mapping['volume']
  end

  # Builds the buffer entry string for the Tecan file for a given mapping.
  #
  # @param mapping [Hash] The buffer mapping entry
  # @param dest_plate_barcode [String] The destination plate barcode
  # @param plate_details [Hash] The destination plate details
  # @param data_object [Hash] The data object containing all mapping info
  # @return [String] The buffer entry string for the Tecan file
  def buffer_entry(mapping, dest_plate_barcode, plate_details, data_object)
    dest_name = data_object['destination'][dest_plate_barcode]['name']
    volume = mapping['buffer_volume']
    vert_map_id = Map::Coordinate.well_description_to_by_column_map_index(mapping['dst_well'],
                                                                          plate_details['plate_size'])
    <<~TECAN
      A;#{buffer_info(vert_map_id)};;#{tecan_precision_value(volume)}
      D;#{dest_plate_barcode};;#{dest_name};#{vert_map_id};;#{tecan_precision_value(volume)}
      W;
    TECAN
  end
end
