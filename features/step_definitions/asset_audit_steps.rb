Given /^asset audit with ID (\d+) is for plate with ID (\d+)$/ do |asset_audit_id, plate_id|
  AssetAudit.find(asset_audit_id).update_attributes!(:asset => Plate.find(plate_id))
end

Given /^the barcode for plate (\d+) is "([^"]*)"$/ do |plate_id, barcode|
  Plate.find(plate_id).update_attributes!(:barcode => barcode)
end


Then /^the activity logging table should be:$/ do |expected_results_table|
  expected_results_table.diff!(table(tableish('table#asset_audits tr', 'td,th')))
end

