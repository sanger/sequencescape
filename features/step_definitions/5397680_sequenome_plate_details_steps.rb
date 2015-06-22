#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
Given /^I have created a sequenom plate$/ do
  input_plate_names = {
    1 => "1220125054743",
    2 => "1220125056761",
    3 => "1220125069815",
    4 => "1220125048766"
  }

  step(%Q{there is a 1 well "Working Dilution" plate with a barcode of "1220125054743"})
  step(%Q{there is a 1 well "Working Dilution" plate with a barcode of "1220125056761"})
  step(%Q{there is a 1 well "Stock Plate" plate with a barcode of "1220125069815"})
  step(%Q{there is a 3 well "Stock Plate" plate with a barcode of "1220125048766"})

  step(%Q{asset with barcode "1220125054743" belongs to study "Study A"})
  step(%Q{asset with barcode "1220125056761" belongs to study "Study A"})
  step(%Q{asset with barcode "1220125069815" belongs to study "Study B"})
  step(%Q{asset with barcode "1220125048766" belongs to study "Study B"})

  seq_plate = SequenomQcPlate.new(
    :plate_prefix      => "QC",
    :user_barcode      => '2470000100730'
  )
  seq_plate.compute_and_set_name(input_plate_names)
  seq_plate.save!


  step(%Q{1 pending delayed jobs are processed})

end

Given /^there is a (\d+) well "([^"]*)" plate with a barcode of "([^"]*)"$/ do |number_of_wells, plate_purpose_name, plate_barcode|
  new_plate = Plate.create!(
    :barcode       => Barcode.number_to_human("#{plate_barcode}"),
    :plate_purpose => PlatePurpose.find_by_name(plate_purpose_name)
  )
  sample = Factory :sample, :name => "#{plate_barcode}_x"

  1.upto(number_of_wells.to_i) do |i|
    new_plate.wells.create!(:map_id => i).aliquots.create!(:sample => sample)
  end

  new_plate.wells.first.primary_aliquot.sample.sample_metadata.update_attributes!(
    :gender => "male"
  )
end

Then /^the table of sequenom plates should be:$/ do |expected_results_table|
  expected_results_table.diff!(table(fetch_table('table#study_list')))
end

Given /^plate "([^"]*)" has (\d+) blank samples$/ do |plate_barcode, number_of_blanks|
  plate = Plate.find_by_barcode(plate_barcode)
  study = plate.study # we need to propagate the study to the new aliquots
  plate.wells.each_with_index do |well,index|
    break if index >= number_of_blanks.to_i
    well.aliquots.clear
    well.aliquots.create!(:sample => Sample.create!(:name => "#{plate_barcode}_#{index}", :empty_supplier_sample_name => true), :study => study)
  end
end

