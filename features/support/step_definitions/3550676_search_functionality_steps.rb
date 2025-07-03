# frozen_string_literal: true

Given /^sample "([^"]+)" is in a sample tube named "([^"]+)"$/ do |sample_name, sample_tube_name|
  sample = Sample.find_by(name: sample_name) or raise StandardError, "Could not find a sample named '#{sample_name}'"
  FactoryBot
    .create(:empty_sample_tube, name: sample_tube_name)
    .tap { |sample_tube| sample_tube.aliquots.create!(sample:) }
end

Then /^the search results I should see are:$/ do |table|
  table.hashes.each do |row|
    step "I should see \"#{row['section count']} #{row['section']}\""
    step "I should see \"#{row['result']}\""
  end
end
