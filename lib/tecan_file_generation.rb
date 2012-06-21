module Sanger
  module Robots
    module Tecan
      class Generator
        def self.mapping(data_object, total_volume)
          raise ArgumentError, "data_object needs to conform to an interface. WIP" if data_object.nil?

          dest_barcode_index = barcode_to_plate_index(data_object["destination"])

          source_barcode_index = source_barcode_to_plate_index(data_object["destination"])
          buffer_data = buffers(data_object, total_volume)
          output_file_contents = [ header(data_object), dyn_mappings(data_object)]
          unless buffer_data.blank?
            output_file_contents << buffer_seperator
            output_file_contents << buffer_data
          end
          output_file_contents << footer(source_barcode_index,dest_barcode_index)

          output_file_contents.join("\n").gsub(/\n\n/,"\n")
        end

        def self.barcode_to_plate_index(plates)
          barcode_lookup = {}
          plates.each_with_index do |plate,index|
            barcode_lookup[plate[0]]= index+1
          end
          barcode_lookup
        end

        def self.source_barcode_to_plate_index(destination)
          all_barcodes = []
          barcode_lookup = {}
          destination.each do |plate_id, plate_info|
            plate_info["mapping"].each do |map_well|
              well = map_well["src_well"]
              all_barcodes << well[0]
            end
          end
          all_barcodes.uniq.each_with_index do |plate,index|
            barcode_lookup[plate]= index+1
          end
          barcode_lookup
        end

        private
        def self.header(data_object)
          "C;\nC; This file created by #{data_object["user"]} on #{data_object["time"]}\nC;"
        end

        def self.dyn_mappings(data_object)
          dyn_mappings = ""
          data_object["destination"].each do |dest_plate_barcode,plate_details|
            mapping_by_well = {}
            plate_details["mapping"].each do |mapping|
              destination_position = Map.description_to_vertical_plate_position(mapping["dst_well"],plate_details["plate_size"])
              mapping_by_well[destination_position] = mapping
            end

            mapping_by_well.sort{|a,b| a[0]<=>b[0]}.each do |dest_position, mapping|
              source_barcode = "#{mapping["src_well"][0]}"
              source_name = data_object["source"]["#{mapping["src_well"][0]}"]["name"]
              source_position  = Map.description_to_vertical_plate_position(mapping["src_well"][1],data_object["source"]["#{mapping["src_well"][0]}"]["plate_size"])
              destination_position = Map.description_to_vertical_plate_position(mapping["dst_well"],plate_details["plate_size"])
              temp = [
                "A;#{source_barcode};;#{source_name};#{source_position};;#{mapping["volume"]}",
                "D;#{dest_plate_barcode};;#{plate_details["name"]};#{destination_position};;#{mapping["volume"]}",
                "W;\n"].join("\n")
              dyn_mappings  += temp
            end
          end
          dyn_mappings
        end

        def self.buffer_seperator
          "C;"
        end

        def self.buffers(data_object, total_volume)
          buffer = []
          data_object["destination"].each do |destination_barcode,destination_details|
            mapping_by_well = {}
            destination_details["mapping"].each do |mapping|
              destination_position = Map.description_to_vertical_plate_position(mapping["dst_well"],destination_details["plate_size"])
              mapping_by_well[destination_position] = mapping
            end
            mapping_by_well.sort{|a,b| a[0]<=>b[0]}.each do |dest_position,mapping|
              if total_volume  > mapping["volume"]
                dest_name = data_object["destination"][destination_barcode]["name"]
                volume = ((total_volume*100) - (mapping["volume"]*100)).to_i.to_f/100
                vert_map_id = Map.description_to_vertical_plate_position(mapping["dst_well"],destination_details["plate_size"])
                buffer << "A;BUFF;;96-TROUGH;#{vert_map_id};;#{volume}\nD;#{destination_barcode};;#{dest_name};#{vert_map_id};;#{volume}\nW;"
              end
            end
          end
          buffer.join("\n") unless buffer.empty?
        end

        def self.footer(source_barcode_index,dest_barcode_index)
          footer = "C;\n"
          source_barcode_index.sort{|a,b| a[1]<=>b[1]}.each do |barcode,index|
            footer += "C; SCRC#{index} = #{barcode}\n"
          end
          footer += "C;\n"
          dest_barcode_index.sort{|a,b| a[1]<=>b[1]}.each do |barcode,index|
            footer += "C; DEST#{index} = #{barcode}\n"
          end
          footer
        end
      end
    end
  end
end