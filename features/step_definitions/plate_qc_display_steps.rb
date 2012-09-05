Given /^I have a Sample Tube "([^"]*)" with a request in "([^"]*)"$/ do |tube_name, study_name|
  study = Study.find_by_name(study_name)
  sample_tube = Factory :empty_sample_tube, :name => tube_name
  sample_tube.aliquots.create!(:sample => Factory(:sample), :study => study)
  Factory :request, :study => study, :asset => sample_tube
end

Given /^I have a Sample Tube "([^"]*)" with a request without a study$/ do |tube_name|
  sample_tube = Factory :sample_tube, :name => tube_name
  Request.create!(:asset => sample_tube)
end

Then /^the asset relations table should be:$/ do |expected_results_table|
  expected_results_table.diff!(table(tableish('table.asset_relations tr', 'td,th')))
end

Then /^the QC table for "([^"]*)" should be:$/ do |table_class_name, expected_results_table|
  expected_results_table.diff!(table(tableish("table##{table_class_name} tr", 'td,th')))
end

Given /^plate "([^"]*)" has QC results$/ do |barcode|
  plate = Plate.find_by_barcode(barcode)
  plate.wells.each_with_index do |well,index|
    well.well_attribute.update_attributes!(
    :measured_volume => 5*index,
    :concentration => 10*index,
    :sequenom_count => index,
    :gel_pass => "OK"
    )
  end
end

