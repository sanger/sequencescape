# frozen_string_literal: true

Given /^an unreleasable lane named "([^"]*)" exists$/ do |name|
  FactoryBot.create(:lane, name: name, external_release: false)
end

Given /^a releasable lane named "([^"]*)" exists$/ do |name|
  FactoryBot.create(:lane, name: name, external_release: true)
end
