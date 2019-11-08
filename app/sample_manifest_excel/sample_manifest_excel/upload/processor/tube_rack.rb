# frozen_string_literal: true

require 'net/http'
require 'json'
require_dependency 'sample_manifest_excel/upload/processor/base'

module SampleManifestExcel
  module Upload
    module Processor
      # TODO: had to explicitly specify the namespace for Base here otherwise it picks up Upload::Base
      class TubeRack < SampleManifestExcel::Upload::Processor::Base
        def run(tag_group)
          return unless valid?

          @tube_rack_information_processed = false
          @tube_rack_barcodes = @upload.data.description_info.select { |key, value| key.start_with?('Rack barcode (') }.values
          @tube_barcodes = @upload.data.column(1).compact   # TODO: do this based on the column name, not number

          process_rack_info = should_process_tube_rack_information?
          if process_rack_info
            if retrieve_scan_results && validate_against_scan_results
              create_tube_racks_and_link_tubes
              @tube_rack_information_processed = true
            else
              return
            end
          end
          update_samples_and_aliquots(tag_group)
          update_sample_manifest
        end

        # if a tube rack record already exists for any of the rack barcodes in the manifest,
        # it has been processed before and should not be re-processed
        def should_process_tube_rack_information?
          @tube_rack_barcodes.each do |barcode|
            existing_barcode_record = Barcode.includes(:asset).find_by(barcode: barcode)
            return false if(existing_barcode_record != nil && existing_barcode_record.asset != nil)
          end
          return true
        end

        def retrieve_scan_results
          @barcode_to_scan_results = {}
          @tube_barcode_to_rack_barcode = {}

          @tube_rack_barcodes.each do |tube_rack_barcode|
            results = retrieve_tube_rack_scan_from_microservice(tube_rack_barcode)
            return false if results == nil

            @barcode_to_scan_results[tube_rack_barcode] = results
            results.keys.each { |tube_barcode| @tube_barcode_to_rack_barcode[tube_barcode] = tube_rack_barcode }
          end

          return true
        end

        def retrieve_tube_rack_scan_from_microservice(tube_rack_barcode)
          # tube_rack_barcode = 'test_valid_file'
          host_name = 'localhost'
          path = '/tube_rack/' + tube_rack_barcode
          port = '5000'
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


        def validate_against_scan_results
          # compare barcodes between manifest and scan
          if @tube_barcodes == @tube_barcode_to_rack_barcode.keys
            return true
          else
            error_message = "The scan and the manifest do not contain identical tube barcodes."
            upload.errors.add(:base, error_message)
            return false
          end

          # TODO: validate coordinates against rack size
        end


        def create_tube_racks_and_link_tubes
          tube_rack_barcode_to_tube_rack = {}
          @tube_rack_barcodes.each do |tube_rack_barcode|
            tube_rack_barcode_to_tube_rack[tube_rack_barcode] = create_tube_rack_if_not_existing(tube_rack_barcode)
          end

          @upload.rows.each do |row|
            # create a barcode for the tube
            tube_barcode = row.value('tube_barcode')
            tube = @upload.cache.find_by(sanger_sample_id: row.sanger_sample_id).asset.labware
            Barcode.create!(asset_id: tube.id, barcode: tube_barcode, format: 7)

            # link the tube to the tube rack
            tube_rack_barcode = @tube_barcode_to_rack_barcode[tube_barcode]
            tube_rack = tube_rack_barcode_to_tube_rack[tube_rack_barcode]
            tube_barcode_to_coordinate = @barcode_to_scan_results[tube_rack_barcode]
            RackedTube.create!(tube_rack: tube_rack, tube: tube, coordinate: tube_barcode_to_coordinate[tube_barcode])
          end
        end

        def create_tube_rack_if_not_existing(tube_rack_barcode)
          barcode = Barcode.includes(:asset).find_by(asset_id: :tube_rack_barcode)

          if barcode == nil
            rack_size = @upload.sample_manifest.tube_rack_purpose.size
            tube_rack = ::TubeRack.create!(size: rack_size)
            barcode = Barcode.create!(asset: tube_rack, barcode: tube_rack_barcode, format: 7)      # TODO: should we ascertain the format from the barcode, or assume it's fluidx?
          else
            tube_rack = barcode.asset
          end

          tube_rack
        end

        def processed?
          samples_updated? && sample_manifest_updated? && aliquots_updated? && @tube_rack_information_processed
        end
      end
    end
  end
end
