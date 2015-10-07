#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011 Genome Research Ltd.
Given /^an accessioning webservice exists which returns a (study|sample|dac|policy) accession number "([^"]*)"$/ do |type, accession_number|
  FakeAccessionService.instance.success(type, accession_number)
end


Given /^an accessioning webservice exists that errors with "([^\"]+)"$/ do |message|
  FakeAccessionService.instance.failure(message)
end

Given /^an accessioning service exists which returns an array express accession number "([^\"]+)"/ do |ae_an|
  FakeAccessionService.instance.success("Study", "EGAS00001000241", <<-XML)
  <EXT_ID accession="#{ae_an}" type="ArrayExpress"/>
  XML

end

Given /^an accessioning webservice is unavailable$/ do
  # Do nothing, just don't tag the scenario!
end

Given /^an accession number is required for study "([^"]*)"$/ do |study_name|
  study = Study.find_by_name(study_name) or raise StandardError, "Cannot find study #{ study_name.inspect }"
  study.enforce_accessioning = true
  study.enforce_data_release = true
  study.save!
end



Then /^I should not have sent an alias to the accessioning service$/ do
  xml = FakeAccessionService.instance.sent.last["SAMPLE"].readlines.to_s
  assert Nokogiri(xml).xpath("/SAMPLE_SET/SAMPLE/@alias").map(&:to_s).empty?, true
end

Then /^I should not have sent an accession number to the accessioning service$/ do
  xml = FakeAccessionService.instance.sent.last["SAMPLE"].readlines.to_s
  assert Nokogiri(xml).xpath("/SAMPLE_SET/SAMPLE/@accession").map(&:to_s).empty?, true
end

Then /^I should have sent an alias to the accessioning service$/ do
  xml = FakeAccessionService.instance.sent.last["SAMPLE"].readlines.to_s
  assert Nokogiri(xml).xpath("/SAMPLE_SET/SAMPLE/@alias").map(&:to_s).empty?, false
end

Then /^I should have sent an accession number to the accessioning service$/ do
  xml = FakeAccessionService.instance.sent.last["SAMPLE"].readlines.to_s
  assert Nokogiri(xml).xpath("/SAMPLE_SET/SAMPLE/@accession").map(&:to_s).empty?, false
end


Then /^I should have received an accession number from the accessioning service$/ do
  assert false, true
  #xml = FakeAccessionService.instance.sent.last["SAMPLE"].readlines.to_s
  #assert Nokogiri(xml).xpath("/SAMPLE_SET/SAMPLE/@alias").map(&:to_s).empty?, true
end
