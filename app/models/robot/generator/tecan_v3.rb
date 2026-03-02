# frozen_string_literal: true
#
# Handles picking file generation for Tecan robots with reusing tips for buffer
# addition steps
class Robot::Generator::TecanV3 < Robot::Generator::TecanV2
  include Robot::Generator::Behaviours::TecanDefault

  # Groups buffer addition steps by channel, adds 'Comment' lines between steps,
  # appends a 'Wash' command at the end of each channel group. This enables
  # reusing tips for buffer addition steps within each channel.
  #
  # @param data_object [Hash] the picking data object
  # @return [String] the buffer addition steps string
  # @see Robot::Generator::Behaviours::TecanDefault#buffers
  # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
  def buffers(data_object)
    data_object = data_object_for_buffers(data_object)
    groups = Hash.new { |h, k| h[k] = [] } # channel => [steps]
    each_mapping(data_object) do |mapping, dest_plate_barcode, plate_details|
      # src_well is checked to distinguish between buffer for sample wells
      # and buffer for empty wells.
      next if mapping.key?('src_well') && total_volume <= mapping['volume']

      dest_name = data_object['destination'][dest_plate_barcode]['name']
      volume = mapping['buffer_volume']
      vert_map_id = description_to_column_index(mapping['dst_well'], plate_details['plate_size'])
      channel = channel_number(vert_map_id)

      # No Wash after each step, as we are reusing tips for each channel.
      step = <<~TECAN.chomp
        A;#{buffer_info(vert_map_id)};;#{tecan_precision_value(volume)}
        D;#{dest_plate_barcode};;#{dest_name};#{vert_map_id};;#{tecan_precision_value(volume)}
      TECAN

      groups[channel] << step
    end

    blocks = groups.keys.sort.map do |channel|
      # Add 'Comment' between steps, append 'Wash', and join lines.
      (intersperse(groups[channel], 'C;') << 'W;').join("\n")
    end
    blocks.join("\n")
  end
  # rubocop:enable Metrics/AbcSize,Metrics/MethodLength

  # Adds a 'Break' command between the buffer and sample addition steps.
  #
  # @return [String] the buffer separator string
  # @see Robot::Generator::TecanV2#buffer_separator
  def buffer_separator
    'B;'
  end

  private

  # Returns the channel number (1-8) for the given index in column order.
  #
  # @param vert_map_id [Integer] the index of well in column order
  # @return [Integer] the channel number (1-8)
  def channel_number(vert_map_id)
    ((vert_map_id - 1) % NUM_BUFFER_CHANNELS) + 1
  end

  # Inserts the given separator element between each element of the given array.
  #
  # @param arr [Array] the array to intersperse
  # @param sep [Object] the separator element
  # @return [Array] the interspersed array
  def intersperse(arr, sep)
    arr.each_with_object([]) { |item, obj| obj << item << sep }.tap(&:pop)
  end
end
