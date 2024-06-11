# frozen_string_literal: true

# rubocop:todo Layout/LineLength
Given /^(?:a|the) (project|study|sample|sample tube|library tube|plate|pulldown multiplexed library tube|multiplexed library tube|faculty sponsor) (?:named|called) "([^"]+)" exists$/ do |type, name|
  # rubocop:enable Layout/LineLength
  FactoryBot.create(type.gsub(/[^a-z0-9]+/, '_').to_sym, name:)
end

Given /^(?:a|the) lane (?:named|called) "([^"]+)" exists$/ do |name|
  FactoryBot.create(:lane, name:)
end
