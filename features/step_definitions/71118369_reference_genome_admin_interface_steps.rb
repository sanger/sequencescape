Given /^study named "([^"]*)" with reference genome id (\d+)$/ do |name_study, reference_id|
  Factory(:study, :name => name_study, :reference_genome_id => reference_id)
end

When /^I (POST|PUT) following XML to see the reference genome on the study called "([^"]*)"$/ do |action, xml, name_study|
 study = Study.find_by_name(name_study)
 When %Q{I #{action} the following XML to "/studies/#{study.id}":}, xml
end

When /^I (POST|PUT) following XML to see the empty reference genome on the study called "([^"]*)"$/ do |action, xml, name_study|
 study = Study.find_by_name(name_study)
 When %Q{I #{action} the following XML to "/studies/#{study.id}":}, xml
end

#When /^I request XML for the study named (.+)$/ do |page_name|
#  page.driver.get(path_to(page_name), nil, 'HTTP_ACCEPT' => 'application/xml')
#end

Then /^including "([^\"]+)" the XML response should be:$/ do |key_regexp, serialized_xml|
  expected = sort_arrays(remove_fields_from(Hash.from_xml(serialized_xml), /^#{key_regexp}$/))
  received = sort_arrays(remove_fields_from(Hash.from_xml(page.body), /^#{key_regexp}$/))
  assert_equal(expected, received, 'XML differs when decoded')
end
