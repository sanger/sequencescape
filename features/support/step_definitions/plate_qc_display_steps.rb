# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

Then /^the QC table for "([^"]*)" should be:$/ do |table_class_name, expected_results_table|
  expected_results_table.diff!(table(fetch_table("table##{table_class_name}")))
end

Given /^plate "([^"]*)" has QC results$/ do |barcode|
  plate = Plate.find_from_barcode('DN' + barcode)
  plate.wells.each_with_index do |well, index|
    well.well_attribute.update_attributes!(
      measured_volume: 5 * index,
      concentration: 10 * index,
      sequenom_count: index,
      gel_pass: 'OK'
    )
  end
end
