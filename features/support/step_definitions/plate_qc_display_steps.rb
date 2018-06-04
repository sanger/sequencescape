
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
