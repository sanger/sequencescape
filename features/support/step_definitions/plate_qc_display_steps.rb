# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

Given /^I have a Sample Tube "([^"]*)" with a request in "([^"]*)"$/ do |tube_name, study_name|
  study = Study.find_by(name: study_name)
  sample_tube = FactoryGirl.create :empty_sample_tube, name: tube_name
  sample_tube.aliquots.create!(sample: FactoryGirl.create(:sample), study: study)
  FactoryGirl.create :request, study: study, asset: sample_tube
end

Given /^I have a Sample Tube "([^"]*)" with a request without a study$/ do |tube_name|
  sample_tube = FactoryGirl.create :sample_tube, name: tube_name
  Request.create!(asset: sample_tube)
end

Then /^the asset relations table should be:$/ do |expected_results_table|
  expected_results_table.diff!(table(fetch_table('table.asset_relations')))
end

Then /^the QC table for "([^"]*)" should be:$/ do |table_class_name, expected_results_table|
  expected_results_table.diff!(table(fetch_table("table##{table_class_name}")))
end

Given /^plate "([^"]*)" has QC results$/ do |barcode|
  plate = Plate.find_by(barcode: barcode)
  plate.wells.each_with_index do |well, index|
    well.well_attribute.update_attributes!(
    measured_volume: 5 * index,
    concentration: 10 * index,
    sequenom_count: index,
    gel_pass: 'OK'
    )
  end
end
