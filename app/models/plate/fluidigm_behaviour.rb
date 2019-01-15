module Plate::FluidigmBehaviour
  class FluidigmError < StandardError; end

  def self.included(base)
    base.class_eval do
      scope :requiring_fluidigm_data, -> {
        fluidigm_request_id = RequestType.find_by!(key: 'pick_to_fluidigm').id

        joins([
          # 'INNER JOIN barcodes ON barcodes.asset_id = assets.id AND barcodes.format = 2',
          'INNER JOIN container_associations AS fluidigm_plate_association ON fluidigm_plate_association.container_id = assets.id', # The fluidigm wells
          "INNER JOIN requests ON requests.target_asset_id = fluidigm_plate_association.content_id AND state = \'passed\' AND requests.request_type_id = #{fluidigm_request_id}", # Link to their requests
          'INNER JOIN well_links AS stock_well_link ON stock_well_link.target_well_id = fluidigm_plate_association.content_id AND type= \'stock\'',
          'LEFT OUTER JOIN events ON eventful_id = assets.id AND eventful_type = "Asset" AND family = "update_fluidigm_plate" AND content = "FLUIDIGM_DATA" '
        ])
          .includes(:barcodes)
          .where('events.id IS NULL')
          .distinct
      }
    end
  end

  def retrieve_fluidigm_data
    ActiveRecord::Base.transaction do
      fluidigm_data = FluidigmFile::Finder.find(fluidigm_barcode)
      return false if fluidigm_data.empty? # Return false if we have no data

      apply_fluidigm_data(FluidigmFile.new(fluidigm_data.content))
      return true
    end
  end

  def apply_fluidigm_data(fluidigm_file)
    qc_assay = QcAssay.new
    raise FluidigmError, 'File does not match plate' unless fluidigm_file.for_plate?(fluidigm_barcode)

    wells.located_at(fluidigm_file.well_locations).include_stock_wells.each do |well|
      well.stock_wells.each do |sw|
        gender_markers = fluidigm_file.well_at(well.map_description).gender_markers.join('')
        loci_passed = fluidigm_file.well_at(well.map_description).count
        QcResult.create!([
          { asset: sw, key: 'gender_markers', assay_type: 'FLUIDIGM', assay_version: 'v0.1', value: gender_markers, units: 'bases', qc_assay: qc_assay },
          { asset: sw, key: 'loci_passed', assay_type: 'FLUIDIGM', assay_version: 'v0.1', value: loci_passed, units: 'bases', qc_assay: qc_assay }
        ])
      end
    end
    events.updated_fluidigm_plate!('FLUIDIGM_DATA')
  end
end
