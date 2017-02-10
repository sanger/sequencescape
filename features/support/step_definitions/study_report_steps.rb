# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

Then /^I should see qc reports table:$/ do |expected_results_table|
  expected_results_table.diff!(table(fetch_table('table#study_list')))
end

Given /^there is (\d+) pending report for study "([^"]*)"$/ do |num_reports, study_name|
  study = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  1.upto(num_reports.to_i) do
    FactoryGirl.create :pending_study_report, study: study, user: @current_user
  end
end

Given /^there is (\d+) completed report for study "([^"]*)"$/ do |num_reports, study_name|
  study = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  1.upto(num_reports.to_i) do
    FactoryGirl.create :completed_study_report, study: study, user: @current_user
  end
end

Then /^I should see the report for "([^"]*)":$/ do |study_name, expected_results_table|
  study = Study.find_by(name: study_name)
  expected_results_table.diff!(CSV.parse(page.source))
end

Then /^the last report for "([^"]*)" should be:$/ do |study_name, expected_results_table|
  study  = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  report = study.study_reports.last or raise StandardError, "Study #{study_name.inspect} has no study reports"
  expected_results_table.diff!(CSV.parse(report.report.file.read))
end

Given /^study "([^"]*)" has a plate "([^"]*)"$/ do |study_name, plate_barcode|
  plate = Plate.create!(barcode: plate_barcode, plate_purpose: PlatePurpose.find_by(name: 'Stock Plate'))
  samples = []
  1.upto(3) do |i|
    well = Well.create!(plate: plate, map_id: i)
    well.aliquots.create!(sample: Sample.create!(name: "Sample_#{plate_barcode}_#{i}"))
    well.well_attribute.update_attributes!(
      gender_markers: %w(F F F F),
      sequenom_count: 29,
      concentration: 1,
      pico_pass: 'Pass',
      gel_pass: 'Pass',
      measured_volume: 500.0
    )
    samples << well.primary_aliquot.sample
  end
  study = Study.find_by(name: study_name)
  RequestFactory.create_assets_requests(plate.wells, study)

  samples[0].external_properties.create!(key: 'genotyping_done', value: 'DNAlab completed: 13')
  samples[1].external_properties.create!(key: 'genotyping_done', value: 'Imported to Illumina: 123')
  samples[2].external_properties.create!(key: 'genotyping_done', value: 'Imported to Illumina: 51| DNAlab completed: 17')
end

Given /^study "([^"]*)" has a plate "([^"]*)" to be volume checked$/ do |study_name, plate_barcode|
  plate = Plate.create!(barcode: plate_barcode, plate_purpose: PlatePurpose.find_by(name: 'Stock Plate'))
  1.upto(24) do |i|
    well = Well.create!(plate: plate, map_id: i)
    well.aliquots.create!(sample: Sample.create!(name: "Sample_#{plate_barcode}_#{i}"))
  end

  study = Study.find_by(name: study_name)
  RequestFactory.create_assets_requests(plate.wells, study)
end

Given /^a study report is generated for study "([^"]*)"$/ do |study_name|
  study_report = StudyReport.create!(study: Study.find_by(name: study_name))
  study_report.perform
  step('2 pending delayed jobs are processed')
end

Then /^each sample name and sanger ID exists in study "([^"]*)"$/ do |study_name|
  study  = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  report = study.study_reports.last or raise StandardError, "Study #{study_name.inspect} has no study reports"

  CSV.parse(report.report.file.read).each_with_index do |row, index|
    next if row[1].empty? || index == 0
    assert_not_nil study.samples.find_by(sanger_sample_id: row[3])
  end
end

Given /^each sample was updated by a sample manifest$/ do
  Sample.find_each do |sample|
    sample.update_attributes!(updated_by_manifest: true)
  end
end
