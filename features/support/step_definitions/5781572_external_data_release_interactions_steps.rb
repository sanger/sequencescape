# frozen_string_literal: true

Given /^a state "([^"]*)" to lane named "([^"]*)"$/ do |status, name|
  FactoryBot.create(:lane, name:, qc_state: status)
end

Given /^an unreleasable lane named "([^"]*)"$/ do |name|
  lane = Lane.joins(:labware).find_by(labware: { name: })
  lane.external_release = false
  lane.save
end

Given /^an releasable lane named "([^"]*)"$/ do |name|
  lane = Lane.joins(:labware).find_by(labware: { name: })
  lane.external_release = true
  lane.save
end
