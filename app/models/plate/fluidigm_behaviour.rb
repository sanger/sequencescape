# frozen_string_literal: true
module Plate::FluidigmBehaviour
  class FluidigmError < StandardError
  end

  def self.included(base) # rubocop:todo Metrics/MethodLength
    base.class_eval do
      scope :requiring_fluidigm_data,
            -> do
              fluidigm_request_ids = RequestType.where(key: 'pick_to_fluidigm').ids

              joins(
                [
                  :well_requests_as_target,
                  "LEFT OUTER JOIN events
            ON eventful_id = #{Plate.table_name}.id
            AND eventful_type = \"#{Plate.base_class.name}\"
            AND family = \"update_fluidigm_plate\"
            AND content = \"FLUIDIGM_DATA\""
                ]
              )
                .includes(:barcodes)
                .where(events: { id: nil }, requests: { request_type_id: fluidigm_request_ids })
                .distinct
            end
    end
  end

  def retrieve_fluidigm_data
    ActiveRecord::Base.transaction do
      fluidigm_data = FluidigmFile::Finder.find(fluidigm_barcode)

      return false if fluidigm_data.empty? # Return false if we have no data

      apply_fluidigm_data(FluidigmFile.new(fluidigm_data.content))
    end
  end

  # rubocop:todo Metrics/MethodLength
  def apply_fluidigm_data(fluidigm_file) # rubocop:todo Metrics/AbcSize
    qc_assay = QcAssay.new
    raise FluidigmError, 'File does not match plate' unless fluidigm_file.for_plate?(fluidigm_barcode)

    wells
      .located_at(fluidigm_file.well_locations)
      .include_stock_wells
      .each do |well|
        well.stock_wells.each do |sw|
          gender_markers = fluidigm_file.well_at(well.map_description).gender_markers.join('')
          loci_passed = fluidigm_file.well_at(well.map_description).count
          QcResult.create!(
            [
              {
                asset: sw,
                key: 'gender_markers',
                assay_type: 'FLUIDIGM',
                assay_version: 'v0.1',
                value: gender_markers,
                units: 'bases',
                qc_assay: qc_assay
              },
              {
                asset: sw,
                key: 'loci_passed',
                assay_type: 'FLUIDIGM',
                assay_version: 'v0.1',
                value: loci_passed,
                units: 'bases',
                qc_assay: qc_assay
              }
            ]
          )
        end
      end
    events.updated_fluidigm_plate!('FLUIDIGM_DATA')
  end
  # rubocop:enable Metrics/MethodLength
end
