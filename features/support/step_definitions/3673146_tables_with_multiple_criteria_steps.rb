# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

Given /^I have five requests for "([^\"]*)"$/ do |pipeline_name|
  pipeline = Pipeline.find_by(name: pipeline_name)
  5.times do |index_i|
    request = step(%Q{I have a request for "#{pipeline_name}"})
    request.asset.name = "Test Asset #{index_i}"
    request.asset.save
    request
  end
end

Then /^the table of requests should be:$/ do |expected_results_table|
  expected_results_table.diff!(table(fetch_table('table#pipeline_inbox')))
end
