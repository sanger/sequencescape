# frozen_string_literal: true

# Transform /^the last plate$/ do |_|
#   Plate.last or raise StandardError, 'There appear to be no plates'
# end

# ParameterType(
#   name: 'plate',
#   regexp: /the last plate/,
#   transformer: -> (_) { Plate.last or raise StandardError, 'There appear to be no plates' }
# )

# Transform /^the last multiplexed library tube$/ do |_|
#   MultiplexedLibraryTube.last or raise StandardError, 'There appear to be no multiplexed library tubes'
# end

Transform /^the plate "([^\"]+)"$/ do |name|
  Plate.find_by(name: name) || raise(StandardError, "Could not find the plate #{name.inspect}")
end

Transform /^the plate with ID (\d+)$/ do |id|
  Plate.find(id)
end

Transform /^the plate creation with ID (\d+)$/ do |id|
  PlateCreation.find(id)
end

Transform /^the tube creation with ID (\d+)$/ do |id|
  TubeCreation.find(id)
end

Transform /^the plate purpose "([^\"]+)"$/ do |name|
  PlatePurpose.find_by(name: name) || raise(StandardError, "Cannot find plate purpose #{name.inspect}")
end

Transform /^the purpose "([^\"]+)"$/ do |name|
  Purpose.find_by(name: name) || raise(StandardError, "Cannot find purpose #{name.inspect}")
end

Transform /^submitted to "([^\"]+)"$/ do |name|
  SubmissionTemplate.find_by(name: name) || raise(StandardError, "Cannot find submission template #{name.inspect}")
end

Transform /^all submissions$/ do |_|
  Submission.all
end

Transform /^([A-H]\d+)-([A-H]\d+)$/ do |start, finish|
  WellRange.new(start, finish)
end

Transform /^the (sample|library) tube "([^\"]+)"$/ do |type, name|
  "#{type}_tube".classify.constantize.find_by(name: name) || raise(StandardError, "Could not find the #{type} tube #{name.inspect}")
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

Transform /^the last batch$/ do |_|
  Batch.last || raise(StandardError, 'There appear to be no batches')
end

Transform /^tag layout template "([^\"]+)"$/ do |name|
  TagLayoutTemplate.find_by(name: name) || raise(StandardError, "Cannot find tag layout template #{name}")
end

Transform /^tag layout with ID (\d+)$/ do |id|
  TagLayout.find(id)
end
