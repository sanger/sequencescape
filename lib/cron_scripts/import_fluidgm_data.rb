class ::Plate

  fluidigm_request_id = RequestType.find_by_key('pick_to_fluidigm').id

  named_scope :requiring_fluidigm_data, {
    :select => 'DISTINCT assets.*, plate_metadata.fluidigm_barcode AS fluidigm_barcode',
    :joins => [

      'INNER JOIN plate_metadata ON plate_metadata.plate_id = assets.id AND plate_metadata.fluidigm_barcode IS NOT NULL', # The fluidigm metadata
      'INNER JOIN container_associations AS fluidigm_plate_association ON fluidigm_plate_association.container_id = assets.id', # The fluidigm wells
      "INNER JOIN requests ON requests.target_asset_id = fluidigm_plate_association.content_id AND state = \'passed\' AND requests.request_type_id = #{fluidigm_request_id}", # Link to their requests

      'INNER JOIN well_links AS stock_well_link ON stock_well_link.target_well_id = fluidigm_plate_association.content_id AND type= \'stock\'',
      'LEFT OUTER JOIN events ON eventful_id = stock_well_link.source_well_id AND eventful_type = "Asset" AND (family = "update_gender_markers" OR family = "update_sequenom_count") AND content = "FLUIDIGM" '
    ],
    :conditions => 'events.id IS NULL'
  }
end


# We don't eager load wells at this stage, as a lot of the time we aren't going to need them.

Plate.requiring_fluidigm_data.find_each do |plate|

  data = IrodsReader::DataObj.find('seq',:fluidigm_barcode=>plate.fluidigm_barcode, :target=>1, :type=>'csv')

  next if data.empty?
  raise StandardError, "Multiple files found" if data.size > 1

  file = FluidigmFile.new(data.first.retrieve)

  raise StandardError, "File does not match plate" unless file.for_plate?(plate.fluidgm_barcode)

  plate.wells.located_at(file.well_locations).include_stock_wells.each do |well|
    well.stock_wells.each do |sw|
      sw.update_gender_markers!( file.well_at(well.map_description).gender_markers,'FLUIDIGM' )
      sw.update_sequenom_count!( file.well_at(well.map_description).gender_markers,'FLUIDIGM' )
    end
  end
end
