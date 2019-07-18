# frozen_string_literal: true

Given /^a state "([^"]*)" to lane named "([^"]*)"$/ do |status, name|
  FactoryBot.create(:lane, name: name, qc_state: status)
end

# This block is disabled when we have the labware table present as part of the AssetRefactor
# Ie. This is what will happens now
AssetRefactor.when_not_refactored do
  Given /^an unreleasable lane named "([^"]*)"$/ do |name|
    lane = Lane.find_by(name: name)
    lane.external_release = false
    lane.save
  end

  Given /^an releasable lane named "([^"]*)"$/ do |name|
    lane = Lane.find_by(name: name)
    lane.external_release = true
    lane.save
  end
end

# This block is enabled when we have the labware table present as part of the AssetRefactor
# Ie. This is what will happen in future
AssetRefactor.when_refactored do
  Given /^an unreleasable lane named "([^"]*)"$/ do |name|
    lane = Lane.joins(:labware).find_by(labware: { name: name })
    lane.external_release = false
    lane.save
  end

  Given /^an releasable lane named "([^"]*)"$/ do |name|
    lane = Lane.joins(:labware).find_by(labware: { name: name })
    lane.external_release = true
    lane.save
  end
end
