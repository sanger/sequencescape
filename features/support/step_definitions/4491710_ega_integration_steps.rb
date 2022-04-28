# frozen_string_literal: true

# rubocop:todo Layout/LineLength
Given /^an accessioning webservice exists which returns a (study|sample|dac|policy) accession number "([^"]*)"$/ do |type, accession_number|
  # rubocop:enable Layout/LineLength
  FakeAccessionService.instance.success(type, accession_number)
end

Given /^an accessioning webservice exists that errors with "([^"]+)"$/ do |message|
  FakeAccessionService.instance.failure(message)
end

Given /^an accessioning service exists which returns an array express accession number "([^"]+)"/ do |ae_an|
  FakeAccessionService.instance.success('Study', 'EGAS00001000241', <<-XML)
  <EXT_ID accession="#{ae_an}" type="ArrayExpress"/>
  XML
end

Given /^an accessioning webservice is unavailable$/ do
  # Do nothing, just don't tag the scenario!
end

Given /^an accession number is required for study "([^"]*)"$/ do |study_name|
  study = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  study.enforce_accessioning = true
  study.enforce_data_release = true
  study.save!
end
