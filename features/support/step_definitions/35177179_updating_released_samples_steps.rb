# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

Given /^the sample name "([^"]*)" has previously been released$/ do |name|
  Sample.find_by(name: name).release
end

When /^I get the XML accession for the sample *"([^\"]+)"$/ do |name|
  sample = Sample.find_by(name: name) or raise StandardError, "Cannot find sample with name #{name.inspect}"
  visit(url_for(controller: 'samples', action: 'show_accession', id: sample.id, format: :xml))
end

When /^ignoring "([^\"]+)" the XML submission for the sample "([^"]*)" should be:$/ do |key_regexp, name, serialized_xml|
  sample = Sample.find_by(name: name) or raise StandardError, "Cannot find sample with name #{name.inspect}"
  accession_service = sample.accession_service
  accessionable_sample = Accessionable::Sample.new(sample)
  submission = Accessionable::Submission.new(accession_service, User.find_by(login: 'me'), accessionable_sample)
  regexp = Regexp.new(key_regexp)
  block  = ->(key) { key.to_s =~ regexp }
  assert_hash_equal(
    sort_arrays(walk_hash_structure(Hash.from_xml(serialized_xml), &block)),
    sort_arrays(walk_hash_structure(Hash.from_xml(submission.xml), &block)),
    'XML differs when decoded'
    )
end
