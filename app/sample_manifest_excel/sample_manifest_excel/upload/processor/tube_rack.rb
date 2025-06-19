# frozen_string_literal: true

require 'net/http'
require 'json'

module SampleManifestExcel
  module Upload
    module Processor
      # Used for processing the upload of sample manifests.
      # Contains behaviour specific to processing 'Tube Rack' manifests.
      # Had to explicitly specify the namespace for Base here otherwise it picks up Upload::Base
      class TubeRack < SampleManifestExcel::Upload::Processor::Base # rubocop:todo Metrics/ClassLength
        include ActiveModel::Validations
        include ::CsvParserClient

        validates_presence_of :tube_rack_barcodes_from_manifest
        attr_reader :tube_rack_barcodes_from_manifest

        def initialize(upload)
          super(upload)
          @tube_rack_information_processed = false
          @tube_rack_barcodes_from_manifest = retrieve_tube_rack_barcodes_from_manifest
          return if @tube_rack_barcodes_from_manifest.nil?

          # The following assumes that the first column of the manifest contains the tube barcode
          @tube_barcodes_from_manifest = upload.data.column(1).compact
          @tube_rack_information_previously_processed = check_if_tube_racks_present
        end

        def run(tag_group) # rubocop:todo Metrics/MethodLength
          return unless valid?

          unless @tube_rack_information_previously_processed
            @rack_size = upload.sample_manifest.tube_rack_purpose.size
            unless retrieve_scan_results && validate_against_scan_results &&
                validate_coordinates(@rack_size, @rack_barcode_to_scan_results)
              return
            end

            success = create_tube_racks_and_link_tubes

            @tube_rack_information_processed = true if success
          end
          update_samples_and_aliquots(tag_group)
          update_sample_manifest
        end

        def retrieve_tube_rack_barcodes_from_manifest
          rack_barcodes_list = upload.data.description_info.select { |key| key.start_with?('Rack barcode (') }.values
          return nil if rack_barcodes_list.any?(nil)

          rack_barcodes_list
        end

        # if a tube rack record already exists for any of the rack barcodes in the manifest,
        # it has been processed before and should not be re-processed
        def check_if_tube_racks_present
          @tube_rack_barcodes_from_manifest.each do |barcode|
            existing_barcode_record = Barcode.includes(:asset).find_by(barcode:)
            return true if !existing_barcode_record.nil? && !existing_barcode_record.asset.nil?
          end
          false
        end

        def retrieve_scan_results
          @rack_barcode_to_scan_results = {}
          @tube_barcode_to_rack_barcode = {}
          @tube_rack_barcodes_from_manifest.each do |tube_rack_barcode|
            results = ::CsvParserClient.get_tube_rack_scan_results(tube_rack_barcode, upload)
            return false if results.nil?

            @rack_barcode_to_scan_results[tube_rack_barcode] = results
            results.keys.each { |tube_barcode| @tube_barcode_to_rack_barcode[tube_barcode] = tube_rack_barcode }
          end

          true
        end

        def validate_against_scan_results
          return true if @tube_barcodes_from_manifest.sort == @tube_barcode_to_rack_barcode.keys.sort

          error_message = 'The scan and the manifest do not contain identical tube barcodes.'
          upload.errors.add(:base, error_message)
          false
        end

        def validate_coordinates(rack_size, rack_barcode_to_scan_results)
          coordinates = rack_barcode_to_scan_results.values.map(&:values).flatten
          invalid_coordinates = ::TubeRack.invalid_coordinates(rack_size, coordinates)

          return true if invalid_coordinates.empty?

          error_message =
            # rubocop:todo Layout/LineLength
            "The following coordinates in the scan are not valid for a tube rack of size #{rack_size}: #{invalid_coordinates}."

          # rubocop:enable Layout/LineLength
          upload.errors.add(:base, error_message)

          false
        end

        def create_tube_racks_and_link_tubes
          rack_barcode_to_tube_rack = create_tube_racks_if_not_existing
          return false if rack_barcode_to_tube_rack.nil?

          success = create_barcodes_for_existing_tubes
          return false unless success

          link_tubes_to_racks(rack_barcode_to_tube_rack)
          true
        end

        def create_tube_racks_if_not_existing
          rack_barcode_to_tube_rack = {}
          @tube_rack_barcodes_from_manifest.each do |tube_rack_barcode|
            created_rack = create_tube_rack_if_not_existing(tube_rack_barcode)
            return nil if created_rack.nil?

            rack_barcode_to_tube_rack[tube_rack_barcode] = created_rack
          end

          rack_barcode_to_tube_rack
        end

        def create_tube_rack_if_not_existing(tube_rack_barcode) # rubocop:todo Metrics/MethodLength
          barcode = Barcode.includes(:asset).find_by(asset_id: tube_rack_barcode)

          if barcode.nil?
            # TODO: Purpose should be set based on what's selected when generating the manifest
            # https://github.com/sanger/sequencescape/issues/2469
            purpose = Purpose.where(target_type: 'TubeRack', size: @rack_size).first
            tube_rack = ::TubeRack.create!(size: @rack_size, plate_purpose_id: purpose&.id)

            barcode_format = Barcode.matching_barcode_format(tube_rack_barcode)
            if barcode_format.nil?
              error_message = "The tube rack barcode '#{tube_rack_barcode}' is not a recognised format."
              upload.errors.add(:base, error_message)
              return nil
            end
            Barcode.create!(labware: tube_rack, barcode: tube_rack_barcode, format: barcode_format)
          else
            tube_rack = barcode.labware
          end

          tube_rack
        end

        def create_barcodes_for_existing_tubes # rubocop:todo Metrics/MethodLength
          upload.rows.each do |row|
            tube_barcode = row.value('tube_barcode')
            tube = row.labware

            # TODO: the below foreign barcode checks are duplicated in sanger_tube_id specialised field file - refactor
            barcode_format = Barcode.matching_barcode_format(tube_barcode)
            if barcode_format.nil?
              error_message = "The tube barcode '#{tube_barcode}' is not a recognised format."
              upload.errors.add(:base, error_message)
              return false
            else
              return false unless check_foreign_barcode_unique(barcode_format, tube_barcode)
            end
            Barcode.create!(asset_id: tube.id, barcode: tube_barcode, format: barcode_format)
          end
        end

        def check_foreign_barcode_unique(foreign_barcode_format, value)
          return true unless Barcode.exists_for_format?(foreign_barcode_format, value)

          upload.errors.add(:base, 'foreign barcode is already in use.')
          false
        end

        def link_tubes_to_racks(rack_barcode_to_tube_rack)
          upload.rows.each do |row|
            tube_barcode = row.value('tube_barcode')
            tube = row.labware
            tube_rack_barcode = @tube_barcode_to_rack_barcode[tube_barcode]
            tube_rack = rack_barcode_to_tube_rack[tube_rack_barcode]
            tube_barcode_to_coordinate = @rack_barcode_to_scan_results[tube_rack_barcode]
            RackedTube.create!(tube_rack: tube_rack, tube: tube, coordinate: tube_barcode_to_coordinate[tube_barcode])
          end
        end

        def processed?
          samples_updated? && sample_manifest_updated? && aliquots_updated? && tube_rack_information_processed?
        end

        def tube_rack_information_processed?
          @tube_rack_information_processed || @tube_rack_information_previously_processed
        end
      end
    end
  end
end
