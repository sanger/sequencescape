# frozen_string_literal: true

Given /^the sample name "([^"]*)" has previously been released$/ do |name|
  Sample.find_by(name:).release
end

When /^ignoring "([^"]+)" the XML submission for the sample "([^"]*)" should be:$/ do |key_regexp, name, serialized_xml|
  sample = Sample.find_by(name:) or raise StandardError, "Cannot find sample with name #{name.inspect}"
  accession_service = AccessionService.select_for_sample(sample)
  accessionable_sample = Accessionable::Sample.new(sample)
  submission = Accessionable::Submission.new(accession_service, User.find_by(login: 'me'), accessionable_sample)
  regexp = Regexp.new(key_regexp)
  block = ->(key) { key.to_s =~ regexp }
  assert_hash_equal(
    sort_arrays(walk_hash_structure(Hash.from_xml(serialized_xml), &block)),
    sort_arrays(walk_hash_structure(Hash.from_xml(submission.xml), &block)),
    'XML differs when decoded'
  )
end
