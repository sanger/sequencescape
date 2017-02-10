# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

Given /^asset audit with ID (\d+) is for plate with ID (\d+)$/ do |asset_audit_id, plate_id|
  AssetAudit.find(asset_audit_id).update_attributes!(asset: Plate.find(plate_id))
end

Given /^the barcode for plate (\d+) is "([^"]*)"$/ do |plate_id, barcode|
  Plate.find(plate_id).update_attributes!(barcode: barcode)
end

Then /^the activity logging table should be:$/ do |expected_results_table|
  expected_results_table.diff!(table(fetch_table('table#asset_audits')))
end

Then /^there is a broadcast event for the last asset audit created$/ do
  audit = AssetAudit.last
  assert audit.present?, 'AssetAudit not found'
  e = BroadcastEvent::AssetAudit.find_by(seed_id: audit.id, seed_type: 'AssetAudit')
  assert e.present?, 'No event for last audit'
  e.to_json
end
