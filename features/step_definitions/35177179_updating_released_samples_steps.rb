Given /^the sample name "([^"]*)" has previously been released$/ do |name|
  Sample.find_by_name(name).release
end

When /^I get the XML accession for the sample *"([^\"]+)"$/ do |name|
  sample = Sample.find_by_name(name) or raise StandardError, "Cannot find sample with name #{ name.inspect }"
  visit(url_for(:controller => 'samples', :action => 'show_accession', :id => sample.id, :format => :xml))
end

When /^ignoring "([^\"]+)" the XML submission for the sample "([^"]*)" should be:$/ do |key_regexp, name, serialized_xml|
  sample = Sample.find_by_name(name) or raise StandardError, "Cannot find sample with name #{ name.inspect }"
  accession_service = sample.accession_service
  accessionable_sample = Accessionable::Sample.new(sample)
  submission = Accessionable::Submission.new(accession_service, User.find_by_login('me'), accessionable_sample)
  regexp = Regexp.new(key_regexp)
  block  = lambda { |key| key.to_s =~ regexp }
  assert_hash_equal(
    sort_arrays(walk_hash_structure(Hash.from_xml(serialized_xml), &block)),
    sort_arrays(walk_hash_structure(Hash.from_xml(submission.xml), &block)),
    'XML differs when decoded'
    )
end
