# frozen_string_literal: true

require_dependency 'sample_manifest_excel/upload/processor/base'

module SampleManifestExcel
  module Upload
    module Processor
      # TODO: had to explicitly specify the namespace for Base here otherwise it picks up Upload::Base
      # TODO: couldn't call this TubeRack because then the TubeRack.create further down thought it should reference this class, not the model
      class TubeRackProcessor < SampleManifestExcel::Upload::Processor::Base
        def run(tag_group)
          return unless valid?


          tube_rack_barcodes_hash = @upload.data.description_info.select { |key, value| key.start_with?('Rack barcode (') }
          tube_rack_barcodes = tube_rack_barcodes_hash.values
          puts "tube_rack_barcodes: #{tube_rack_barcodes}"

          tube_rack_barcodes.each do |tube_rack_barcode|
            create_tube_rack_if_not_existing(tube_rack_barcode)
          end


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
          end

        end


      end
    end
  end
end
