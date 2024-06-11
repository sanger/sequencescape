# frozen_string_literal: true

Then /^I should see qc reports table:$/ do |expected_results_table|
  expected_results_table.diff!(table(fetch_table('table#study_list')))
end

Given /^there is (\d+) pending report for study "([^"]*)"$/ do |num_reports, study_name|
  study = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  1.upto(num_reports.to_i) { FactoryBot.create :pending_study_report, study:, user: @current_user }
end

Given /^there is (\d+) completed report for study "([^"]*)"$/ do |num_reports, study_name|
  study = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  1.upto(num_reports.to_i) { FactoryBot.create :completed_study_report, study:, user: @current_user }
end

Then /^I should see the report for "([^"]*)":$/ do |study_name, expected_results_table|
  study = Study.find_by(name: study_name)
  expected_results_table.diff!(CSV.parse(page.source))
end

Then /^the last report for "([^"]*)" should be:$/ do |study_name, expected_results_table|
  study = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  report = study.study_reports.last or raise StandardError, "Study #{study_name.inspect} has no study reports"
  report_contents = report.report.file.read
  expected_results_table.diff!(CSV.parse(report_contents))
end

Given /^study "([^"]*)" has a plate "([^"]*)"$/ do |study_name, plate_barcode|
  plate =
    FactoryBot.create(
      :plate,
      barcode: plate_barcode,
      plate_purpose: PlatePurpose.find_by(name: 'Stock Plate'),
      well_count: 3,
      well_order: :row_order
    )
  samples = []
  plate.wells.each_with_index do |well, i|
    # well = Well.create!(plate: plate, map_id: i)
    well.aliquots.create!(sample: Sample.create!(name: "Sample_#{plate_barcode}_#{i + 1}"))
    well.well_attribute.update!(
      gender_markers: %w[F F F F],
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
end

Given /^study "([^"]*)" has a plate "([^"]*)" to be volume checked$/ do |study_name, plate_barcode|
  study = Study.find_by(name: study_name)
  plate =
    FactoryBot.create :plate,
                      purpose: PlatePurpose.find_by(name: 'Stock Plate'),
                      barcode: plate_barcode,
                      well_count: 24,
                      well_factory: :untagged_well,
                      well_order: :row_order,
                      studies: [study]

  RequestFactory.create_assets_requests(plate.wells, study)
end

Given /^a study report is generated for study "([^"]*)"$/ do |study_name|
  study_report = StudyReport.create!(study: Study.find_by(name: study_name))
  study_report.perform
end

Given /^each sample was updated by a sample manifest$/ do
  Sample.find_each { |sample| sample.update!(updated_by_manifest: true) }
end
