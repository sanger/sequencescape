# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

Given /^study named "([^"]*)" with reference genome id (\d+)$/ do |name_study, reference_id|
  FactoryGirl.create(:study, name: name_study, reference_genome_id: reference_id)
end

When /^I (POST|PUT) following XML to see the reference genome on the study called "([^"]*)"$/ do |action, xml, name_study|
 study = Study.find_by(name: name_study)
 step %Q{I #{action} the following XML to "/studies/#{study.id}":}, xml
end

When /^I (POST|PUT) following XML to see the empty reference genome on the study called "([^"]*)"$/ do |action, xml, name_study|
 study = Study.find_by(name: name_study)
 step %Q{I #{action} the following XML to "/studies/#{study.id}":}, xml
end

# When /^I request XML for the study named (.+)$/ do |page_name|
#  page.driver.get(path_to(page_name), nil, 'HTTP_ACCEPT' => 'application/xml')
# end

Then /^including "([^\"]+)" the XML response should be:$/ do |key_regexp, serialized_xml|
  expected = sort_arrays(remove_fields_from(Hash.from_xml(serialized_xml), /^#{key_regexp}$/))
  received = sort_arrays(remove_fields_from(Hash.from_xml(page.source), /^#{key_regexp}$/))
  assert_equal(expected, received, 'XML differs when decoded')
end
