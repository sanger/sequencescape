# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

module Plate::FluidigmBehaviour
  class FluidigmError < StandardError; end

  def self.included(base)
    base.class_eval do
      scope :requiring_fluidigm_data, -> {
        fluidigm_request_id = RequestType.find_by!(key: 'pick_to_fluidigm').id

        select('DISTINCT assets.*, plate_metadata.fluidigm_barcode AS fluidigm_barcode')
        .joins([
          'INNER JOIN plate_metadata ON plate_metadata.plate_id = assets.id AND plate_metadata.fluidigm_barcode IS NOT NULL', # The fluidigm metadata
          'INNER JOIN container_associations AS fluidigm_plate_association ON fluidigm_plate_association.container_id = assets.id', # The fluidigm wells
          "INNER JOIN requests ON requests.target_asset_id = fluidigm_plate_association.content_id AND state = \'passed\' AND requests.request_type_id = #{fluidigm_request_id}", # Link to their requests

          'INNER JOIN well_links AS stock_well_link ON stock_well_link.target_well_id = fluidigm_plate_association.content_id AND type= \'stock\'',
          'LEFT OUTER JOIN events ON eventful_id = assets.id AND eventful_type = "Asset" AND family = "update_fluidigm_plate" AND content = "FLUIDIGM_DATA" '
        ])
        .where('events.id IS NULL')
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
    raise FluidigmError, 'File does not match plate' unless fluidigm_file.for_plate?(fluidigm_barcode)

    wells.located_at(fluidigm_file.well_locations).include_stock_wells.each do |well|
      well.stock_wells.each do |sw|
        sw.update_gender_markers!(fluidigm_file.well_at(well.map_description).gender_markers, 'FLUIDIGM')
        sw.update_sequenom_count!(fluidigm_file.well_at(well.map_description).count, 'FLUIDIGM')
      end
    end
    events.updated_fluidigm_plate!('FLUIDIGM_DATA')
  end
end
