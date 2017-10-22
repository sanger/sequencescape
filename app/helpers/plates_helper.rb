# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015 Genome Research Ltd.

module PlatesHelper
  class AliquotError < StandardError; end

  def padded_wells_by_row(plate, overide = nil)
    wells = wells_hash(plate)
    padded_well_name_with_index(plate) do |padded_name, index|
        index = padded_name == overide ? :overide : index
        yield(padded_name, *wells[index])
    end
  end

  private

  def well_properties(well)
    [
      well.sample.name,
      '',
      well.sample.sample_metadata.sample_type || 'Unknown'
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
        raise AliquotError if well.aliquots.count > 1
        wells[well.map.row_order] = well_properties(well)
      end
    end
  end

  def self.event_family_for_pick(plate_purpose_name)
    "picked_well_to_#{plate_purpose_name.tr(' ', "_").downcase}_plate"
  end
end
