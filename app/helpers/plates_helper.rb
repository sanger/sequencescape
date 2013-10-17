module PlatesHelper

  class AliquotError < StandardError; end

  def padded_wells_by_row(plate,overide =nil )
    wells = wells_hash(plate)
    padded_well_name_with_index(plate) do |padded_name,index|
        index = padded_name == overide ? :overide : index
        yield(padded_name,*wells[index])
    end
  end

  private

  def well_properties(well)
    [
      well.sample.name,
      '',
      well.sample.sample_metadata.sample_type||'Unknown'
    ]
  end

  def padded_well_name_with_index(plate)
    ('A'...(?A+(plate.size/12)).chr).each_with_index do |row,ri|
      (1..12).each_with_index do |col,ci|
        padded_name = "%s%02d" % [row, col]
        index = ci+(ri*12)
        yield(padded_name,index)
      end
    end
  end

  def wells_hash(plate)
    Hash.new {|h,i| h[i] = ['[ Empty ]','', 'NTC'] }.tap do |wells|
      wells[:overide] = ['','', 'NTC']
      plate.wells.each do |well|
        raise AliquotError if well.aliquots.count > 1
        wells[well.map.row_order] = well_properties(well)
      end
    end
  end


end
