# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015 Genome Research Ltd.

Transform /^submitted to "([^\"]+)"$/ do |name|
  SubmissionTemplate.find_by(name: name) or raise StandardError, "Cannot find submission template #{name.inspect}"
end

Transform /^all submissions$/ do |_|
  Submission.all
end

class WellRange
  WELL_REGEXP = /^([A-H])(\d+)$/

  def initialize(start, finish)
    start_match, finish_match = WELL_REGEXP.match(start), WELL_REGEXP.match(finish)
    @rows    = (start_match[1]..finish_match[1])
    @columns = (start_match[2].to_i..finish_match[2].to_i)
  end

  def include?(well)
    include_well_location?(well.map.description)
  end

  def include_well_location?(location)
    well_match = WELL_REGEXP.match(location)
    @rows.include?(well_match[1]) and @columns.include?(well_match[2].to_i)
  end
  private :include_well_location?

  def to_a
    [].tap do |wells|
      (1..12).each do |column|
        ('A'..'H').each do |row|
          well = "#{row}#{column}"
          wells << well if include_well_location?(well)
        end
      end
    end
  end

  delegate :size, to: :to_a
end

Transform /^([A-H]\d+)-([A-H]\d+)$/ do |start, finish|
  WellRange.new(start, finish)
end

def create_submission_of_assets(template, assets, request_options = {})
  template.create_and_build_submission!(
    user: FactoryGirl.create(:user),
    study: FactoryGirl.create(:study),
    project: FactoryGirl.create(:project),
    assets: assets,
    request_options: request_options
  )
  step 'all pending delayed jobs are processed'
end

Given /^"([^\"]+)" of (the plate .+) have been (submitted to "[^"]+")$/ do |range, plate, template|
  request_options = { read_length: 100, fragment_size_required_from: 100, fragment_size_required_to: 200 }
  request_options[:bait_library_name] = 'Human all exon 50MB' if template.name =~ /Pulldown I?SC/

  create_submission_of_assets(
    template,
    plate.wells.select(&range.method(:include?)),
    request_options
  )
end

Given /^"([^\"]+)" of (the plate .+) and (the plate .+) both been (submitted to "[^"]+")$/ do |range, plate, plate2, template|
  request_options = { read_length: 100, fragment_size_required_from: 100, fragment_size_required_to: 200 }
  request_options[:bait_library_name] = 'Human all exon 50MB' if template.name =~ /Pulldown I?SC/
  create_submission_of_assets(
    template,
    plate.wells.select(&range.method(:include?)) + plate2.wells.select(&range.method(:include?)),
    request_options
  )
end

Given /^"([^\"]+)" of (the plate .+) are part of the same submission$/ do |range, plate|
  submission = FactoryGirl.create :submission
  plate.wells.select(&range.method(:include?)).each do |well|
    FactoryGirl.create :transfer_request, submission: submission, target_asset: well
  end
end

Given /^"([^\"]+)" of (the plate .+) have been failed$/ do |range, plate|
  plate.wells.select(&range.method(:include?)).each do |well|
    well.aliquots.clear
    well.requests_as_target.map(&:destroy)
  end
end

Given /^"([^\"]+)" of (the plate .+) have been (submitted to "[^\"]+") with the following request options:$/ do |range, plate, template, table|
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

Given /^H12 on (the plate .+) is empty$/ do |plate|
  plate.wells.located_at('H12').first.aliquots.clear
end

def work_pipeline_for(submissions, name, template = nil)
  final_plate_type = PlatePurpose.find_by(name: name) or raise StandardError, "Cannot find #{name.inspect} plate type"
  template       ||= TransferTemplate.find_by(name: 'Pool wells based on submission') or raise StandardError, 'Cannot find pooling transfer template'

  source_plates = submissions.map { |submission| submission.requests.first.asset.plate }.uniq
  raise StandardError, "Submissions appear to come from non-unique plates: #{source_plates.inspect}" unless source_plates.size == 1

  source_plate = source_plates.first
  source_plate.wells.each do |w|
    next if w.aliquots.empty?
    FactoryGirl.create(:tag).tag!(w) unless w.primary_aliquot.tag.present? # Ensure wells are tagged
    w.requests_as_source.first.start! # Ensure request is considered started
  end

  source_plate.plate_purpose.child_relationships.create!(child: final_plate_type, transfer_request_type: RequestType.transfer)

  final_plate_type.create!.tap do |final_plate|
    AssetLink.create!(ancestor: source_plate, descendant: final_plate)
    template.create!(source: source_plate, destination: final_plate, user: FactoryGirl.create(:user))
  end
end

def finalise_pipeline_for(plate)
  plate.purpose.connect_requests(plate, 'qc_complete')
  plate.wells.each do |well|
    well.requests_as_target.each do |r|
      target_state = r.library_creation? ? 'passed' : 'qc_complete'
      r.update_attributes!(state: target_state)
    end
  end
end

# A bit of a fudge but it'll work for the moment.  We essentially link the last plate of the different
# pipelines back to the stock plate directly.  Eventually these can grow into a proper work through of
# a pipeline.
Given /^(all submissions) have been worked until the last plate of the "Pulldown WGS" pipeline$/ do |submissions|
  work_pipeline_for(submissions, 'WGS lib pool')
end
Given /^(all submissions) have been worked until the last plate of the "Pulldown SC" pipeline$/ do |submissions|
  work_pipeline_for(submissions, 'SC cap lib pool')
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

Transform /^the (sample|library) tube "([^\"]+)"$/ do |type, name|
  "#{type}_tube".classify.constantize.find_by(name: name) or raise StandardError, "Could not find the #{type} tube #{name.inspect}"
end

Transform /^the (?:.+\s)?plate "([^\"]+)"$/ do |name|
  Plate.find_by(name: name) || raise(ActiveRecord::RecordNotFound, "Could not find Plate names #{name} in #{Plate.all.pluck(:name)}")
end

Transform /^the (?:.+) with UUID "([^\"]+)"$/ do |uuid|
  Uuid.lookup_single_uuid(uuid).resource
end

Transform /^the study "([^\"]+)"$/ do |name|
  Study.find_by!(name: name)
end

Then /^the state of (the .+) should be "([^\"]+)"$/ do |target, state|
  assert_equal(state, target.state, 'State is invalid')
end

Given /^all of the wells on (the plate .+) are in an asset group called "([^"]+)" owned by (the study .+)$/ do |plate, name, study|
  AssetGroup.create!(study: study, name: name, assets: plate.wells)
end

Then /^all "([^\"]+)" requests should have the following details:$/ do |name, table|
  request_type = RequestType.find_by(name: name) or raise StandardError, "Could not find request type #{name.inspect}"
  raise StandardError, "No requests of type #{name.inspect}" if request_type.requests.empty?

  results = request_type.requests.all.map do |request|
    Hash[table.raw.map do |attribute, _|
      [attribute, attribute.split('.').inject(request.request_metadata) { |m, s| m.send(s) }]
    end]
  end.uniq!
  expected = Hash[table.raw.map do |attribute, value|
    value = value.to_i if ['fragment_size_required_from', 'fragment_size_required_to'].include?(attribute)
    [attribute, value]
  end]
  assert_equal([expected], results, 'Request details are not identical')
end

Given /^"([^\"]+-[^\"]+)" of the plate with ID (\d+) are empty$/ do |range, id|
  Plate.find(id).wells.select(&range.method(:include?)).each { |well| well.aliquots.clear }
end

Given /^all requests are in the last submission$/ do
  submission = Submission.last or raise StandardError, 'There are no submissions!'
  Request.update_all("submission_id=#{submission.id}")
end

Given /^(the plate .+) will pool into 1 tube$/ do |plate|
  stock_plate = PlatePurpose.find(2).create!(:do_not_create_wells) { |p| p.wells = [FactoryGirl.create(:empty_well)] }
  stock_well  = stock_plate.wells.first
  submission  = Submission.create!(user: FactoryGirl.create(:user))

  AssetLink.create!(ancestor: stock_plate, descendant: plate)

  plate.wells.in_column_major_order.readonly(false).each do |well|
    RequestType.transfer.create!(asset: stock_well, target_asset: well, submission: submission)
    well.stock_wells.attach!([stock_well])
    FactoryGirl.create :library_creation_request, asset: stock_well, target_asset: well, submission: submission
  end
end

Then /^the user (should|should not) accept responsibility for pulldown library creation requests from the plate "(.*?)"$/ do |accept, plate_name|
  Plate.find_by(name: plate_name).wells.each do |well|
    well.requests.where_is_a?(Pulldown::Requests::LibraryCreation).each { |r| assert_equal accept == 'should', r.request_metadata.customer_accepts_responsibility }
  end
end
