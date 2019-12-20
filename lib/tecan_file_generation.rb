module Sanger
  module Robots
    module Tecan
      class Generator
        class << self
          def mapping(data_object, total_volume)
            raise ArgumentError, 'data_object needs to conform to an interface. WIP' if data_object.nil?

            dest_barcode_index = barcode_to_plate_index(data_object['destination'])

            source_barcode_index = source_barcode_to_plate_index(data_object['destination'])
            buffer_data = buffers(data_object, total_volume)
            output_file_contents = [header(data_object)]
            if buffer_data.present?
              output_file_contents << buffer_data
              output_file_contents << buffer_seperator
            end
            output_file_contents << dyn_mappings(data_object)
            output_file_contents << footer(source_barcode_index, dest_barcode_index)

            output_file_contents.join("\n").gsub(/\n\n/, "\n")
          end

          def barcode_to_plate_index(plates)
            barcode_lookup = {}
            plates.each_with_index do |plate, index|
              barcode_lookup[plate[0]] = index + 1
            end
            barcode_lookup
          end

          def source_barcode_to_plate_index(destination)
            all_barcodes = []
            barcode_lookup = {}
            destination.each do |_plate_id, plate_info|
              # sort by destination well to make sure the plates are put the right way round for the robot
              # 'SCRC1' goes into the 1st row of the fluidigm chip, and 'SCRC2' into the 2nd
              mapping_sorted = sort_mapping_by_destination_well(plate_info['mapping'])
              mapping_sorted.each do |map_well|
                well = map_well['src_well']
                all_barcodes << well[0]
              end
            end
            all_barcodes.uniq.each_with_index do |plate, index|
              barcode_lookup[plate] = index + 1
            end
            barcode_lookup
          end

          def sort_mapping_by_destination_well(mapping)
            mapping.sort do |a, b|
              a['dst_well'] <=> b['dst_well']
            end
          end

          private

          def header(data_object)
            "C;\nC; This file created by #{data_object["user"]} on #{data_object["time"]}\nC;"
          end

          def tecan_precision_value(value)
            value.to_f.round(configatron.tecan_precision)
          end

          def each_mapping(data_object)
            data_object['destination'].each do |dest_plate_barcode, plate_details|
              mapping_by_well = Hash.new { |h, i| h[i] = [] }
              plate_details['mapping'].each do |mapping|
                destination_position = Map::Coordinate.description_to_vertical_plate_position(mapping['dst_well'], plate_details['plate_size'])
                mapping_by_well[destination_position] << mapping
              end

              mapping_by_well.sort_by { |a| a[0] }.each do |_dest_position, mappings|
                mappings.each do |mapping|
                  yield(mapping, dest_plate_barcode, plate_details)
                end
              end
            end
          end

          def dyn_mappings(data_object)
            dyn_mappings = ''
            each_mapping(data_object) do |mapping, dest_plate_barcode, plate_details|
              source_barcode = (mapping['src_well'][0]).to_s
              source_name = data_object['source'][(mapping['src_well'][0]).to_s]['name']
              source_position = Map::Coordinate.description_to_vertical_plate_position(mapping['src_well'][1], data_object['source'][(mapping['src_well'][0]).to_s]['plate_size'])
              destination_position = Map::Coordinate.description_to_vertical_plate_position(mapping['dst_well'], plate_details['plate_size'])
              temp = [
                "A;#{source_barcode};;#{source_name};#{source_position};;#{tecan_precision_value(mapping['volume'])}",
                "D;#{dest_plate_barcode};;#{plate_details["name"]};#{destination_position};;#{tecan_precision_value(mapping['volume'])}",
                "W;\n"
              ].join("\n")
              dyn_mappings += temp
            end
            dyn_mappings
          end

          def buffer_seperator
            'C;'
          end

          def buffers(data_object, total_volume)
            buffer = []
            each_mapping(data_object) do |mapping, dest_plate_barcode, plate_details|
              if total_volume > mapping['volume']
                dest_name = data_object['destination'][dest_plate_barcode]['name']
                volume = mapping['buffer_volume']
                vert_map_id = Map::Coordinate.description_to_vertical_plate_position(mapping['dst_well'], plate_details['plate_size'])
                buffer << "A;BUFF;;96-TROUGH;#{vert_map_id};;#{tecan_precision_value(volume)}\nD;#{dest_plate_barcode};;#{dest_name};#{vert_map_id};;#{tecan_precision_value(volume)}\nW;"
              end
            end
            buffer.join("\n")
          end

          def footer(source_barcode_index, dest_barcode_index)
            footer = "C;\n"
            source_barcode_index.sort_by { |a| a[1] }.each do |barcode, index|
              footer += "C; SCRC#{index} = #{barcode}\n"
            end
            footer += "C;\n"
            dest_barcode_index.sort_by { |a| a[1] }.each do |barcode, index|
              footer += "C; DEST#{index} = #{barcode}\n"
            end
            footer
          end
        end
      end
    end
  end
end
