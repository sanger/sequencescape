# frozen_string_literal: true

require 'active_support'

def create_submission_of_assets(template, assets, request_options = {})
  Delayed::Worker.delay_jobs = false
  submission = template.create_with_submission!(
    user: FactoryBot.create(:user),
    study: FactoryBot.create(:study),
    project: FactoryBot.create(:project),
    assets: assets,
    request_options: request_options
  ).submission
  submission.built!
  Delayed::Worker.delay_jobs = true
end

Given '{well_range} of {plate_uuid} have been {submitted_to}' do |range, plate, template|
  request_options = { read_length: 100, fragment_size_required_from: 100, fragment_size_required_to: 200 }
  request_options[:bait_library_name] = 'Human all exon 50MB' if template.name.match?(/Pulldown I?SC/)

  create_submission_of_assets(
    template,
    plate.wells.select(&range.method(:include?)),
    request_options
  )
end

Given '{well_range} of {plate_name} have been {submitted_to}' do |range, plate, template|
  request_options = { read_length: 100, fragment_size_required_from: 100, fragment_size_required_to: 200 }
  request_options[:bait_library_name] = 'Human all exon 50MB' if template.name.match?(/Pulldown I?SC/)

  create_submission_of_assets(
    template,
    plate.wells.select(&range.method(:include?)),
    request_options
  )
end

Given '{well_range} of {plate_name} are part of the same submission' do |range, plate|
  submission = FactoryBot.create :submission
  plate.wells.select(&range.method(:include?)).each do |well|
    FactoryBot.create :transfer_request, submission: submission, target_asset: well
  end
end

Given '{well_range} of {plate_name} have been failed' do |range, plate|
  plate.wells.select(&range.method(:include?)).each do |well|
    well.aliquots.clear
    well.requests_as_target.map(&:destroy)
  end
end

Given '{well_range} of {plate_name} have been {submitted_to} with the following request options:' do |range, plate, template, table|
  create_submission_of_assets(
    template,
    plate.wells.select(&range.method(:include?)),
    Hash[table.raw]
  )
end

Given '{well_range} of {plate_uuid} have been {submitted_to} with the following request options:' do |range, plate, template, table|
  create_submission_of_assets(
    template,
    plate.wells.select(&range.method(:include?)),
    Hash[table.raw]
  )
end

Given /^the plate (.+) has been submitted to "([^"]+)"$/ do |info, template|
  step(%Q{"A1-H12" of the plate #{info} have been submitted to "#{template}"})
end

Given /^the plate (.+) and (.+) have been submitted to "([^"]+)"$/ do |info, info2, template|
  step(%Q{"A1-H12" of the plate #{info} and the plate #{info2} both been submitted to "#{template}"})
end

Given 'H12 on {asset_name} is empty' do |plate|
  plate.wells.located_at('H12').first.aliquots.clear
end

def work_pipeline_for(submissions, name, template = nil)
  final_plate_type = PlatePurpose.find_by(name: name) or raise StandardError, "Cannot find #{name.inspect} plate type"
  template       ||= TransferTemplate.find_by(name: 'Pool wells based on submission') or raise StandardError, 'Cannot find pooling transfer template'

  source_plates = submissions.map { |submission| submission.requests.first!.asset.plate }.uniq
  raise StandardError, "Submissions appear to come from non-unique plates: #{source_plates.inspect}" unless source_plates.size == 1

  source_plate = source_plates.first

  source_plate.wells.with_aliquots.each do |w|
    FactoryBot.create(:tag).tag!(w) if w.primary_aliquot.tag.blank? # Ensure wells are tagged
    w.requests_as_source.first.start! # Ensure request is considered started
  end

  final_plate_type.create!.tap do |final_plate|
    AssetLink.create!(ancestor: source_plate, descendant: final_plate)
    template.create!(source: source_plate, destination: final_plate, user: FactoryBot.create(:user))
  end
end

def finalise_pipeline_for(plate)
  plate.purpose.connect_requests(plate, 'qc_complete')
  plate.wells.each do |well|
    well.requests_as_target.each do |r|
      r.update!(state: 'passed')
    end
    well.transfer_requests_as_target.each do |r|
      r.update!(state: 'qc_complete')
    end
  end
end

# A bit of a fudge but it'll work for the moment.  We essentially link the last plate of the different
# pipelines back to the stock plate directly.  Eventually these can grow into a proper work through of
# a pipeline.
Given /^(all submissions) have been worked until the last plate of the "Pulldown WGS" pipeline$/ do |submissions|
  work_pipeline_for(submissions, 'WGS lib pool')
end

Given /^(all submissions) have been worked until the last plate of the "Pulldown ISC" pipeline$/ do |submissions|
  work_pipeline_for(submissions, 'ISC cap lib pool')
end
Given /^(all submissions) have been worked until the last plate of the "Illumina-B STD" pipeline$/ do |submissions|
  work_pipeline_for(submissions, 'ILB_STD_PCRXP')
end
Given /^(all submissions) have been worked until the last plate of the "Illumina-B HTP" pipeline$/ do |submissions|
  plate = work_pipeline_for(submissions, 'Lib PCR-XP', TransferTemplate.find_by!(name: 'Transfer columns 1-1'))
  finalise_pipeline_for(plate)
end

Then 'the state of {uuid} should be {string}' do |target, state|
  assert_equal(state, target.state, 'State is invalid')
end

Then 'the state of {asset_name} should be {string}' do |target, state|
  assert_equal(state, target.state, 'State is invalid')
end

Given 'all of the wells on {plate_name} are in an asset group called {string} owned by {study_name}' do |plate, name, study|
  AssetGroup.create!(study: study, name: name, assets: plate.wells)
end

Then /^all "([^"]+)" requests should have the following details:$/ do |name, table|
  request_type = RequestType.find_by(name: name) or raise StandardError, "Could not find request type #{name.inspect}"
  raise StandardError, "No requests of type #{name.inspect}" if request_type.requests.empty?

  results = request_type.requests.all.map do |request|
    Hash[table.raw.map do |attribute, _|
      [attribute, attribute.split('.').inject(request.request_metadata) { |m, s| m.send(s) }]
    end]
  end.uniq!
  expected = Hash[table.raw.map do |attribute, value|
    value = value.to_i if %w[fragment_size_required_from fragment_size_required_to].include?(attribute)
    [attribute, value]
  end]
  assert_equal([expected], results, 'Request details are not identical')
end

Given /^all requests are in the last submission$/ do
  submission = Submission.last or raise StandardError, 'There are no submissions!'
  Request.update_all("submission_id=#{submission.id}")
end

Given /^all transfer requests are in the last submission$/ do
  submission = Submission.last or raise StandardError, 'There are no submissions!'
  TransferRequest.update_all("submission_id=#{submission.id}")
end

Given '{plate_name} will pool into 1 tube' do |plate|
  well_count = plate.wells.count
  stock_plate = FactoryBot.create :full_stock_plate, well_count: well_count
  stock_wells = stock_plate.wells
  submission = Submission.create!(user: FactoryBot.create(:user))

  AssetLink.create!(ancestor: stock_plate, descendant: plate)

  plate.wells.in_column_major_order.readonly(false).each_with_index do |well, i|
    stock_well = stock_wells[i]
    FactoryBot.create(:library_creation_request, asset: stock_well, target_asset: well, submission: submission)
    FactoryBot.create(:transfer_request, asset: stock_well, target_asset: well, submission: submission)
    well.stock_wells.attach!([stock_well])
  end
end

Then /^the user (should|should not) accept responsibility for pulldown library creation requests from the plate "(.*?)"$/ do |accept, plate_name|
  Plate.find_by(name: plate_name).wells.each do |well|
    well.requests.where_is_a(Pulldown::Requests::LibraryCreation).each { |r| assert_equal accept == 'should', r.request_metadata.customer_accepts_responsibility }
  end
end
