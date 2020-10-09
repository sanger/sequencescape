# frozen_string_literal: true

Given /^(?:a|the) (project|study|sample|sample tube|library tube|plate|pulldown multiplexed library tube|multiplexed library tube|faculty sponsor) (?:named|called) "([^"]+)" exists$/ do |type, name|
  FactoryBot.create(type.gsub(/[^a-z0-9]+/, '_').to_sym, name: name)
end

Given /^(?:a|the) lane (?:named|called) "([^"]+)" exists$/ do |name|
  FactoryBot.create(:lane, name: name)
end
