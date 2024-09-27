# frozen_string_literal: true

def upload_submission_spreadsheet(name, encoding = nil)
  attach_file('bulk_submission_spreadsheet', Rails.root.join('features', 'submission', 'csv', "#{name}.csv"))
  step("I select \"#{encoding}\" from 'Encoding'") if encoding
  click_button 'Create Bulk submission'
end

def upload_custom_row_submission
  attach_file(
    'bulk_submission_spreadsheet',
    Rails.root.join('features', 'submission', 'csv', 'template_for_bulk_submission.csv')
  )
  click_button 'Create Bulk submission'
end

# rubocop:todo Layout/LineLength
When /^I have a plate '(.*)' that has a well in location 'A1' that contains the sample '(.*)'$/ do |asset_name, sample_name|
  # rubocop:enable Layout/LineLength
  sample = Sample.find_by(name: sample_name)
  plate = FactoryBot.create :plate, name: asset_name
  plate.wells.construct!
  well = plate.wells.first
  well.aliquots.create!(sample:)
end

When /^the plate '(.*)' has a barcode '(.*)'$/ do |name, barcode|
  bc = SBCF::SangerBarcode.new(prefix: 'DN', number: barcode).human_barcode
  Plate.find_by(name:).primary_barcode.update(barcode: bc)
end

When /^the sample '(.*)' belongs to study '(.*)'$/ do |sample_name, study_name|
  sample = Sample.find_by(name: sample_name)
  study = Study.find_by(name: study_name)
  sample.studies << study
end

# rubocop:todo Layout/LineLength
When /^I upload a file with a plate 'AssetTest' with a well in location 'A1' that contains the sample 'SampleTest' for study 'StudyB'$/ do
  # rubocop:enable Layout/LineLength
  upload_custom_row_submission
end

Then /^the sample '(.*)' should belong to study '(.*)'$/ do |sample_name, study_name|
  assert_equal true, Sample.find_by(name: sample_name).studies.include?(Study.find_by(name: study_name))
end

Then /^the sample '(.*)' should not belong to study '(.*)'$/ do |sample_name, study_name|
  assert_equal false, Sample.find_by(name: sample_name).studies.include?(Study.find_by(name: study_name))
end

When /^I upload a file with valid data for 1 tube submissions$/ do
  upload_submission_spreadsheet('1_tube_submission')
end

When /^I upload a file with 2 valid SC submissions$/ do
  upload_submission_spreadsheet('2_valid_sc_submissions')
end

Then /^there should be an order with the bait library name set to "([^"]+)"$/ do |name|
  assert_not_nil(
    Order.all.detect { |o| o.request_options[:bait_library_name] == name },
    "There is no order with the bait library name set to #{name.inspect}"
  )
end

Then /^the last submission should contain two assets$/ do
  assert_equal 2, Submission.last.orders.reduce(0) { |total, order| total + order.assets.count }
end

Then 'the last submission should contain the tube with barcode {string}' do |barcode|
  assert Submission.last.orders.flat_map(&:assets).detect { |a| a.human_barcode == barcode }
end
