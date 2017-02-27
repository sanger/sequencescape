# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

Given /^sample "([^\"]+)" is in a sample tube named "([^\"]+)"$/ do |sample_name, sample_tube_name|
  sample = Sample.find_by(name: sample_name) or raise StandardError, "Could not find a sample named '#{sample_name}'"
  FactoryGirl.create(:empty_sample_tube, name: sample_tube_name).tap { |sample_tube| sample_tube.aliquots.create!(sample: sample) }
end

Then /^the search results I should see are:$/ do |table|
  table.hashes.each do |row|
    step %Q{I should see "1 #{row['section']}"}
    step %Q{I should see "#{row['result']}"}
  end
end
