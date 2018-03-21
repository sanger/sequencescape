# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

Given(/^plate "([^"]*)" with (\d+) samples in study "([^"]*)" exists$/) do |plate_barcode, number_of_samples, study_name|
  step(%Q{I have a plate "#{plate_barcode}" in study "#{study_name}" with #{number_of_samples} samples in asset group "Plate asset group #{plate_barcode}"})
  step(%Q{plate "#{plate_barcode}" has concentration results})
  step(%Q{plate "#{plate_barcode}" has measured volume results})
end

Given(/^plate "([^"]*)" has concentration results$/) do |plate_barcode|
  plate = Plate.find_by(barcode: plate_barcode)
  plate.wells.each_with_index do |well, index|
    well.well_attribute.update_attributes!(concentration: index * 40)
  end
end

Given(/^plate "([^"]*)" has nonzero concentration results$/) do |plate_barcode|
  step(%Q{plate "#{plate_barcode}" has concentration results})

  plate = Plate.find_by(barcode: plate_barcode)
  plate.wells.each_with_index do |well, _index|
    if well.well_attribute.concentration == 0.0
      well.well_attribute.update_attributes!(concentration: 1)
    end
  end
end

Given(/^plate "([^"]*)" has measured volume results$/) do |plate_barcode|
  plate = Plate.find_by(barcode: plate_barcode)
  plate.wells.each_with_index do |well, index|
    well.well_attribute.update_attributes!(measured_volume: index * 11)
  end
end

Then /^I should see the cherrypick worksheet table:$/ do |expected_results_table|
  actual_table = table(fetch_table('table.plate_layout'))
  expected_results_table.column_names.each do |column_name|
    expected_results_table.map_column!(column_name.to_s) { |text| text.squish }
  end
  expected_results_table.diff!(actual_table)
end

Given(/^I have a tag group called "([^"]*)" with (\d+) tags$/) do |tag_group_name, number_of_tags|
  oligos = %w(ATCACG CGATGT TTAGGC TGACCA)
  tag_group = TagGroup.create!(name: tag_group_name)
  tags = []
  1.upto(number_of_tags.to_i) do |i|
    Tag.create!(oligo: oligos[(i - 1) % oligos.size], map_id: i, tag_group_id: tag_group.id)
  end
end

Given(/^I have a plate "([^"]*)" with the following wells:$/) do |plate_barcode, well_details|
  plate = FactoryGirl.create :plate, barcode: plate_barcode
  well_details.hashes.each do |well_detail|
    well = Well.create!(map: Map.find_by(description: well_detail[:well_location], asset_size: 96), plate: plate)
    well.well_attribute.update_attributes!(concentration: well_detail[:measured_concentration], measured_volume: well_detail[:measured_volume])
  end
end
