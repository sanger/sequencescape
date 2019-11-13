# frozen_string_literal: true

require 'net/http'
require 'json'
require_dependency 'sample_manifest_excel/upload/processor/base'

module SampleManifestExcel
  module Upload
    module Processor
      # TODO: had to explicitly specify the namespace for Base here otherwise it picks up Upload::Base
      # Used for processing the upload of sample manifests.
      # Contains behaviour specific to processing 'Tube Rack' manifests.
      class TubeRack < SampleManifestExcel::Upload::Processor::Base
        include ActiveModel::Validations

        validates_presence_of :tube_rack_barcodes_from_manifest
        attr_reader :tube_rack_barcodes_from_manifest

        def initialize(upload)
          super(upload)
          @tube_rack_information_processed = false
          @tube_rack_barcodes_from_manifest = retrieve_tube_rack_barcodes_from_manifest
          @tube_barcodes_from_manifest = @upload.data.column(1).compact # TODO: do this based on the column name, not number
          @should_process_tube_rack_information = should_process_tube_rack_information?
        end

        def run(tag_group)
          return unless valid?

          if @should_process_tube_rack_information
            @rack_size = @upload.sample_manifest.tube_rack_purpose.size
            return unless retrieve_scan_results && validate_against_scan_results && validate_coordinates(@rack_size, @rack_barcode_to_scan_results)

            create_tube_racks_and_link_tubes

            @tube_rack_information_processed = true
          end
          update_samples_and_aliquots(tag_group)
          update_sample_manifest
        end

        def retrieve_tube_rack_barcodes_from_manifest
          rack_barcodes_list = @upload.data.description_info.select { |key| key.start_with?('Rack barcode (') }.values
          return nil if rack_barcodes_list.any?(nil)
          return rack_barcodes_list
        end

        # if a tube rack record already exists for any of the rack barcodes in the manifest,
        # it has been processed before and should not be re-processed
        def should_process_tube_rack_information?
          @tube_rack_barcodes_from_manifest.each do |barcode|
            existing_barcode_record = Barcode.includes(:asset).find_by(barcode: barcode)
            return false if !existing_barcode_record.nil? && !existing_barcode_record.asset.nil?
          end unless @tube_rack_barcodes_from_manifest.nil?
          true
        end

        def retrieve_scan_results
          @rack_barcode_to_scan_results = {}
          @tube_barcode_to_rack_barcode = {}
          @tube_rack_barcodes_from_manifest.each do |tube_rack_barcode|
            results = if Rails.configuration.do_tube_rack_scan_callout
                        retrieve_tube_rack_scan_from_microservice(tube_rack_barcode)
                      else
                        mock_scan_result
                      end
            return false if results.nil?

            @rack_barcode_to_scan_results[tube_rack_barcode] = results
            results.keys.each { |tube_barcode| @tube_barcode_to_rack_barcode[tube_barcode] = tube_rack_barcode }
          end

          true
        end

        def retrieve_tube_rack_scan_from_microservice(tube_rack_barcode)
          # tube_rack_barcode = 'test_valid_file'
          host_name = Rails.configuration.tube_rack_scans_microservice_endpoint
          path = '/tube_rack/' + tube_rack_barcode
          port = Rails.configuration.tube_rack_scans_microservice_port
          response = Net::HTTP.get_response(host_name, path, port)

          begin
            scan_results = JSON.parse(response.body)
          rescue JSON::JSONError => e
            error_message = "Response when trying to retrieve scan (tube rack with barcode #{tube_rack_barcode}) was not valid JSON so could not be understood. Error message: #{e.message}"
            upload.errors.add(:base, error_message)
            return nil
          end

          unless response.code == '200'
            error_message = "Scan could not be retrieved for tube rack with barcode #{tube_rack_barcode}. Service responded with status code #{response.code} "
            error_message += " and the following message: #{scan_results['error']}"
            upload.errors.add(:base, error_message)
            return nil
          end

          scan_results['layout'] || nil
        end

        def mock_scan_result
          {
            'TB11111110' => 'e8',
            'TB11111111' => 'b4'
          }
        end

        def validate_against_scan_results
          return true if @tube_barcodes_from_manifest.sort == @tube_barcode_to_rack_barcode.keys.sort

          error_message = 'The scan and the manifest do not contain identical tube barcodes.'
          upload.errors.add(:base, error_message)
          false
        end

        def validate_coordinates(rack_size, rack_barcode_to_scan_results)
          rack_layout_map = {
            48 => {
              'rows' => 6,
              'columns' => 8
            },
            96 => {
              'rows' => 8,
              'columns' => 12
            }
          }

          num_rows = rack_layout_map[rack_size]['rows']
          num_columns = rack_layout_map[rack_size]['columns']
          valid_row_values = TubeRack.generate_valid_row_values(num_rows)
          valid_column_values = (1..num_columns).to_a

          rack_barcode_to_scan_results.each_value do |scan_results|
            scan_results.each_value do |coordinate|
              row = coordinate.split(//)[0].capitalize
              column = coordinate.split(//)[1]
              unless valid_row_values.include?(row) && valid_column_values.include?(column.to_i)
                error_message = "The coordinate '#{coordinate}' in the scan is not valid for a tube rack of size #{rack_size}."
                upload.errors.add(:base, error_message)
                return false
              end
            end
          end

          true
        end

        def self.generate_valid_row_values(num_rows)
          output = []
          count = 1
          ('A'..'Z').each do |letter|
            output << letter if count <= num_rows
            count += 1
          end
          output
        end

        def create_tube_racks_and_link_tubes
          tube_rack_barcode_to_tube_rack = {}
          @tube_rack_barcodes_from_manifest.each do |tube_rack_barcode|
            tube_rack_barcode_to_tube_rack[tube_rack_barcode] = create_tube_rack_if_not_existing(tube_rack_barcode)
          end

          @upload.rows.each do |row|
            # create a barcode for the tube
            tube_barcode = row.value('tube_barcode')
            tube = row.labware
            Barcode.create!(asset_id: tube.id, barcode: tube_barcode, format: 7)

            # link the tube to the tube rack
            tube_rack_barcode = @tube_barcode_to_rack_barcode[tube_barcode]
            tube_rack = tube_rack_barcode_to_tube_rack[tube_rack_barcode]
            tube_barcode_to_coordinate = @rack_barcode_to_scan_results[tube_rack_barcode]
            RackedTube.create!(tube_rack: tube_rack, tube: tube, coordinate: tube_barcode_to_coordinate[tube_barcode])
          end
        end

        def create_tube_rack_if_not_existing(tube_rack_barcode)
          barcode = Barcode.includes(:asset).find_by(asset_id: :tube_rack_barcode)

          if barcode.nil?
            tube_rack = ::TubeRack.create!(size: @rack_size)
            Barcode.create!(asset: tube_rack, barcode: tube_rack_barcode, format: 7) # TODO: should we ascertain the format from the barcode, or assume it's fluidx?
          else
            tube_rack = barcode.asset
          end

          tube_rack
        end

        def processed?
          samples_updated? && sample_manifest_updated? && aliquots_updated? && tube_rack_information_processed?
        end

        def tube_rack_information_processed?
          @tube_rack_information_processed || !@should_process_tube_rack_information
        end
      end
    end
  end
end
