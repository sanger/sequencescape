# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.
module Sanger
  module Robots
    module Tecan
      class Generator
        def self.mapping(data_object, total_volume)
          raise ArgumentError, 'data_object needs to conform to an interface. WIP' if data_object.nil?
          dest_barcode_index = barcode_to_plate_index(data_object['destination'])

          source_barcode_index = source_barcode_to_plate_index(data_object['destination'])
          buffer_data = buffers(data_object, total_volume)
          output_file_contents = [header(data_object)]
          unless buffer_data.blank?
            output_file_contents << buffer_data
            output_file_contents << buffer_seperator
          end
          output_file_contents << dyn_mappings(data_object)
          output_file_contents << footer(source_barcode_index, dest_barcode_index)

          output_file_contents.join("\n").gsub(/\n\n/, "\n")
        end

        def self.barcode_to_plate_index(plates)
          barcode_lookup = {}
          plates.each_with_index do |plate, index|
            barcode_lookup[plate[0]] = index + 1
          end
          barcode_lookup
        end

        def self.source_barcode_to_plate_index(destination)
          all_barcodes = []
          barcode_lookup = {}
          destination.each do |_plate_id, plate_info|
            plate_info['mapping'].each do |map_well|
              well = map_well['src_well']
              all_barcodes << well[0]
            end
          end
          all_barcodes.uniq.each_with_index do |plate, index|
            barcode_lookup[plate] = index + 1
          end
          barcode_lookup
        end

        private

        def self.header(data_object)
          "C;\nC; This file created by #{data_object["user"]} on #{data_object["time"]}\nC;"
        end

        def self.tecan_precision_value(value)
          "%.#{configatron.tecan_precision}f" % value
        end

        def self.each_mapping(data_object)
          data_object['destination'].each do |dest_plate_barcode, plate_details|
            mapping_by_well = Hash.new { |h, i| h[i] = [] }
            plate_details['mapping'].each do |mapping|
              destination_position = Map::Coordinate.description_to_vertical_plate_position(mapping['dst_well'], plate_details['plate_size'])
              mapping_by_well[destination_position] << mapping
            end

            mapping_by_well.sort { |a, b| a[0] <=> b[0] }.each do |_dest_position, mappings|
              mappings.each do |mapping|
                yield(mapping, dest_plate_barcode, plate_details)
              end
            end
          end
        end

        def self.dyn_mappings(data_object)
          dyn_mappings = ''
          each_mapping(data_object) do |mapping, dest_plate_barcode, plate_details|
            source_barcode = (mapping['src_well'][0]).to_s
            source_name = data_object['source'][(mapping['src_well'][0]).to_s]['name']
            source_position = Map::Coordinate.description_to_vertical_plate_position(mapping['src_well'][1], data_object['source'][(mapping['src_well'][0]).to_s]['plate_size'])
            destination_position = Map::Coordinate.description_to_vertical_plate_position(mapping['dst_well'], plate_details['plate_size'])
            temp = [
              "A;#{source_barcode};;#{source_name};#{source_position};;#{tecan_precision_value(mapping['volume'])}",
              "D;#{dest_plate_barcode};;#{plate_details["name"]};#{destination_position};;#{tecan_precision_value(mapping['volume'])}",
              "W;\n"].join("\n")
            dyn_mappings += temp
          end
          dyn_mappings
        end

        def self.buffer_seperator
          'C;'
        end

        def self.buffers(data_object, total_volume)
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

        def self.footer(source_barcode_index, dest_barcode_index)
          footer = "C;\n"
          source_barcode_index.sort { |a, b| a[1] <=> b[1] }.each do |barcode, index|
            footer += "C; SCRC#{index} = #{barcode}\n"
          end
          footer += "C;\n"
          dest_barcode_index.sort { |a, b| a[1] <=> b[1] }.each do |barcode, index|
            footer += "C; DEST#{index} = #{barcode}\n"
          end
          footer
        end
      end
    end
  end
end
