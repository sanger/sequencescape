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
    include_well_location?(well.map.description)
  end

  def include_well_location?(location)
    well_match = WELL_REGEXP.match(location)
    @rows.include?(well_match[1]) and @columns.include?(well_match[2].to_i)
  end
  private :include_well_location?

  def to_a(&block)
    [].tap do |wells|
      (1..12).each do |column|
        ('A'..'H').each do |row|
          well = "#{row}#{column}"
          wells << well if include_well_location?(well)
        end
      end
    end
  end

  def size
    to_a.size
  end
end

Transform /^([A-H]\d+)-([A-H]\d+)$/ do |start, finish|
  WellRange.new(start, finish)
end

def create_submission_of_assets(template, assets, request_options = {})
  template.create_and_build_submission!(
    :user            => Factory(:user),
    :study           => Factory(:study),
    :project         => Factory(:project),
    :assets          => assets,
    :request_options => request_options
  )

  Given 'all pending delayed jobs are processed'
end

Given /^"([^\"]+)" of (the plate .+) have been (submitted to "[^"]+")$/ do |range, plate, template|
  request_options = { :read_length => 100 }
  request_options[:bait_library_name] = 'Human all exon 50MB' if template.name =~ /Pulldown I?SC/

  create_submission_of_assets(
    template,
    plate.wells.select(&range.method(:include?)),
    request_options
  )
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
  Given %Q{"A1-H12" of the plate #{info} have been submitted to "#{template}"}
end

Given /^H12 on (the plate .+) is empty$/ do |plate|
  plate.wells.located_at('H12').first.aliquots.clear
end

def work_pipeline_for(submissions, name)
  final_plate_type = PlatePurpose.find_by_name(name) or raise StandardError, "Cannot find #{name.inspect} plate type"
  template         = TransferTemplate.find_by_name('Pool wells based on submission') or raise StandardError, 'Cannot find pooling transfer template'

  source_plates = submissions.map { |submission| submission.requests.first.asset.plate }.uniq
  raise StandardError, "Submissions appear to come from non-unique plates: #{source_plates.inspect}" unless source_plates.size == 1

  source_plate = source_plates.first
  source_plate.wells.each do |w|
    Factory(:tag).tag!(w) unless w.primary_aliquot.tag.present? # Ensure wells are tagged
    w.requests_as_source.first.start!                           # Ensure request is considered started
  end

  source_plate.plate_purpose.child_relationships.create!(:child => final_plate_type, :transfer_request_type => RequestType.transfer)

  final_plate_type.create!.tap do |final_plate|
    AssetLink.create!(:ancestor => source_plate, :descendant => final_plate)
    template.create!(:source => source_plate, :destination => final_plate, :user => Factory(:user))
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
  expected = Hash[table.raw.map do |attribute, value|
    value = value.to_i if [ 'fragment_size_required_from', 'fragment_size_required_to' ].include?(attribute)
    [ attribute, value ]
  end]
  assert_equal([ expected ], results, "Request details are not identical")
end

Given /^"([^\"]+-[^\"]+)" of the plate with ID (\d+) are empty$/ do |range, id|
  Plate.find(id).wells.select(&range.method(:include?)).each { |well| well.aliquots.clear }
end

Then /^all of the pulldown library creation requests to (the multiplexed library tube .+) should be billed to their project$/ do |tube|
  requests = tube.requests_as_target.where_is_a?(Pulldown::Requests::LibraryCreation).all
  assert(!requests.empty?, "There are expected to be a number of pulldown requests")
  assert(requests.all? { |r| not r.billing_events.charged_to_project.empty? }, "There are requests that have not billed the project")
end

Then /^all of the pulldown library creation requests to (the multiplexed library tube .+) should not have billing$/ do |tube|
  requests = tube.requests_as_target.where_is_a?(Pulldown::Requests::LibraryCreation).all
  assert(!requests.empty?, "There are expected to be a number of pulldown requests")
  assert(requests.all? { |r| r.billing_events.empty? }, "There are requests that have billing events")
end

Then /^all of the illumina-b library creation requests to (the multiplexed library tube .+) should be billed to their project$/ do |tube|
  requests = tube.requests_as_target.where_is_a?(IlluminaB::Requests::StdLibraryRequest).all
  assert(!requests.empty?, "There are expected to be a number of pulldown requests")
  assert(requests.all? { |r| not r.billing_events.charged_to_project.empty? }, "There are requests that have not billed the project")
end

Then /^all of the illumina-b library creation requests to (the multiplexed library tube .+) should not have billing$/ do |tube|
  requests = tube.requests_as_target.where_is_a?(IlluminaB::Requests::StdLibraryRequest).all
  assert(!requests.empty?, "There are expected to be a number of pulldown requests")
  assert(requests.all? { |r| r.billing_events.empty? }, "There are requests that have billing events")
end

Given /^all requests are in the last submission$/ do
  submission = Submission.last or raise StandardError, "There are no submissions!"
  Request.update_all("submission_id=#{submission.id}")
end

Given /^(the plate .+) will pool into 1 tube$/ do |plate|
  stock_plate = PlatePurpose.find(2).create!(:do_not_create_wells) { |p| p.wells = [Factory(:empty_well)] }
  stock_well  = stock_plate.wells.first
  submission  = Submission.create!(:user => Factory(:user))

  AssetLink.create!(:ancestor => stock_plate, :descendant => plate)

  plate.wells.in_column_major_order.each do |well|
    RequestType.transfer.create!(:asset => stock_well, :target_asset => well, :submission => submission)
  end
end
