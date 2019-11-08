# frozen_string_literal: true

require 'net/http'
require_dependency 'sample_manifest_excel/upload/processor/base'

module SampleManifestExcel
  module Upload
    module Processor
      # TODO: had to explicitly specify the namespace for Base here otherwise it picks up Upload::Base
      # TODO: couldn't call this TubeRack because then the TubeRack.create further down thought it should reference this class, not the model
      class TubeRackProcessor < SampleManifestExcel::Upload::Processor::Base
        def run(tag_group)
          return unless valid?


          @tube_rack_barcodes = @upload.data.description_info.select { |key, value| key.start_with?('Rack barcode (') }.values

          retrieve_scan_results
          validate_against_scan_results
          create_tube_racks_and_link_tubes

          update_samples_and_aliquots(tag_group)
          # TODO: if not uploaded before,
          # create tube rack if doesn't already exist
          # update existing tube with barcode (from manifest)
            # find existing tube through sanger sample id -> sample manifest asset -> receptacle -> labware (not through aliquot, in case it's the wrong aliquot)
          # insert racked tube, with coordinate (from scan)
          update_sample_manifest
        end


        def create_tube_rack_if_not_existing(tube_rack_barcode)
          puts "**** create_tube_rack_if_not_existing ****"
          barcode = Barcode.includes(:asset).find_by(asset_id: :tube_rack_barcode)
          puts "**** barcode: #{barcode} ****"

          if barcode == nil
            rack_size = @upload.sample_manifest.tube_rack_purpose.size
            puts "**** rack_size: #{rack_size} ****"
            tube_rack = TubeRack.create(size: rack_size)
            Barcode.create(asset_id: tube_rack.id, barcode: tube_rack_barcode, format: 7)      # TODO: should we ascertain the format from the barcode, or assume it's fluidx?
          else
            tube_rack = barcode.asset
          end

          tube_rack
        end

        def retrieve_scan_results
          @barcode_to_scan_results = {}
          @tube_rack_barcodes.each do |tube_rack_barcode|
            @barcode_to_scan_results[tube_rack_barcode] = retrieve_tube_rack_scan_from_microservice(tube_rack_barcode)
          end
        end

        def retrieve_tube_rack_scan_from_microservice(tube_rack_barcode)
          # call the microservice here
          # tube_rack_barcode = 'test'
          # going to change the microservice so that the 'layout' is an object, not an array, and so that the keys are the barcodes
          response = Net::HTTP.get_response('localhost', '/rack/' + tube_rack_barcode, '5000')
          puts "**** response: #{response} *****"
          scan_results = JSON.parse(response.body)
          scan_results["layout"]
        end

        def validate_against_scan_results
          # compare barcodes and coordinates between manifest and scan
        end

        def create_tube_racks_and_link_tubes
          @tube_rack_barcodes.each do |tube_rack_barcode|
            tube_rack = create_tube_rack_if_not_existing(tube_rack_barcode)
            puts "**** tube_rack: #{tube_rack} ****"
          end
        end

      end
    end
  end
end
