Transform /^submitted to "([^\"]+)"$/ do |name|
  SubmissionTemplate.find_by_name(name) or raise StandardError, "Cannot find submission template #{name.inspect}"
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
    well_match = WELL_REGEXP.match(well.map.description)
    @rows.include?(well_match[1]) and @columns.include?(well_match[2].to_i)
  end
end

Transform /^([A-H]\d+)-([A-H]\d+)$/ do |start, finish|
  WellRange.new(start, finish)
end

def create_submission_of_assets(template, assets, request_options = {})
  submission = template.new_submission(
    :user            => Factory(:user),
    :study           => Factory(:study),
    :project         => Factory(:project),
    :assets          => assets,
    :request_options => request_options
  )
  submission.save!
  submission.built!

  Given 'all pending delayed jobs are processed'
end

Given /^"([^\"]+)" of (the plate .+) have been (submitted to "[^"]+")$/ do |range, plate, template|
  create_submission_of_assets(
    template,
    plate.wells.select(&range.method(:include?)), {
      :read_length => 100
    }
  )
end

Given /^"([^\"]+)" of (the plate .+) have been (submitted to "[^\"]+") with the following request options:$/ do |range, plate, template, table|
  create_submission_of_assets(
    template,
    plate.wells.select(&range.method(:include?)),
    Hash[table.raw]
  )
end

Given /^the plate (.+) has been submitted to "([^"]+)"$/ do |info, template|
  Given %Q{"A1-H12" of the plate #{info} have been submitted to "#{template}"}
end

def work_pipeline_for(submissions, name)
  final_plate_type = PlatePurpose.find_by_name(name) or raise StandardError, "Cannot find #{name.inspect} plate type"
  template         = TransferTemplate.find_by_name('Pool wells based on submission') or raise StandardError, 'Cannot find pooling transfer template'

  source_plates = submissions.map { |submission| submission.requests.first.asset.plate }.uniq
  raise StandardError, "Submissions appear to come from non-unique plates: #{source_plates.inspect}" unless source_plates.size == 1
  template.create!(:source => source_plates.first, :destination => final_plate_type.create!, :user => Factory(:user))
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

Transform /^the (sample|library) tube "([^\"]+)"$/ do |type, name|
  "#{type}_tube".classify.constantize.find_by_name(name) or raise StandardError, "Could not find the #{type} tube #{name.inspect}"
end

Transform /^the (?:.+\s)?plate "([^\"]+)"$/ do |name|
  Plate.find_by_name(name) or raise StandardError, "Could not find the plate #{name.inspect}"
end

Transform /^the (?:.+) with UUID "([^\"]+)"$/ do |uuid|
  Uuid.lookup_single_uuid(uuid).resource
end

Transform /^the study "([^\"]+)"$/ do |name|
  Study.find_by_name(name) or raise StandardError, "Could not find the study #{name.inspect}"
end

Then /^the state of (the .+) should be "([^\"]+)"$/ do |target, state|
  assert_equal(state, target.state, "State is invalid")
end

Given /^all of the wells on (the plate .+) are in an asset group called "([^"]+)" owned by (the study .+)$/ do |plate, name, study|
  AssetGroup.create!(:study => study, :name => name, :assets => plate.wells)
end

Then /^all "([^\"]+)" requests should have the following details:$/ do |name, table|
  request_type = RequestType.find_by_name(name) or raise StandardError, "Could not find request type #{name.inspect}"
  raise StandardError, "No requests of type #{name.inspect}" if request_type.requests.empty?

  results = request_type.requests.all.map do |request|
    Hash[table.raw.map do |attribute,_|
      [ attribute, attribute.split('.').inject(request.request_metadata) { |m, s| m.send(s) } ]
    end]
  end.uniq!
  assert_equal([Hash[table.raw]], results, "Request details are not identical")
end

Given /^"([^\"]+-[^\"]+)" of the plate with ID (\d+) are empty$/ do |range, id|
  Plate.find(id).wells.select(&range.method(:include?)).each { |well| well.aliquots.clear }
end
