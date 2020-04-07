module PlatesHelper
  class AliquotError < StandardError; end

  def padded_wells_by_row(plate, overide = nil)
    wells = wells_hash(plate)
    padded_well_name_with_index(plate) do |padded_name, index|
      index = padded_name == overide ? :overide : index
      yield(padded_name, *wells[index])
    end
  end

  def valid_options_for_params(val)
    return {} unless val.valid_options

    val.valid_options.merge(
      valid_dilution_factors: val.valid_options[:valid_dilution_factors].map(&:to_s)
    )
  end

  def plate_creator_parameters_json(plate_creators)
    return({}.to_json) unless plate_creators

    plate_creators.each_with_object({}) do |val, memo|
      memo[val.name] = valid_options_for_params(val)
    end.to_json
  end

  private

  # Remove deprecate use of Well.sample
  # Github Issue https://github.com/sanger/sequencescape/issues/1908
  def well_properties(well)
    raise AliquotError if well.samples.length > 1

    sample = well.samples.first
    [
      sample.name,
      '',
      sample.sample_metadata.sample_type || 'Unknown'
    ]
  end

  def padded_well_name_with_index(plate)
    ('A'...(?A.getbyte(0) + (plate.size / 12)).chr).each_with_index do |row, ri|
      (1..12).each_with_index do |col, ci|
        padded_name = '%s%02d' % [row, col]
        index = ci + (ri * 12)
        yield(padded_name, index)
      end
    end
  end

  def wells_hash(plate)
    Hash.new { |h, i| h[i] = ['[ Empty ]', '', 'NTC'] }.tap do |wells|
      wells[:overide] = ['', '', 'NTC']
      plate.wells.each do |well|
        wells[well.map.row_order] = well_properties(well)
      end
    end
  end

  def self.event_family_for_pick(plate_purpose_name)
    "picked_well_to_#{plate_purpose_name.tr(' ', "_").downcase}_plate"
  end
end
