# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

Given /^I have a tag instance called "([^\"]+)"$/ do |name|
  FactoryGirl.create(:tag_instance, name: name)
end

Given /^I have a hybridization spiked buffer called "([^\"]+)"$/ do |name|
  FactoryGirl.create(:spiked_buffer, name: name)
end
Given /^I have a tag called "([^\"]+)"$/ do |name|
  FactoryGirl.create(:tag, map_id: name)
end

Then /^the "([^\"]+)" of the asset "([^\"]+)" should be "([^\"]+)"$/ do |field, id, value|
  asset = Asset.find(id)
  assert_equal value, asset.send(field).to_s
end

Given /^the "([^\"]+)" of the asset "([^\"]+)" is "([^\"]+)"$/ do |field, id, value|
  asset = Asset.find(id)
  asset.send("#{field}=", value)
  asset.save!
end

Then /^(.+) asset (?:called|named) "([^\"]+)"(.*)$/ do |pre, name, post|
  asset = Asset.find_by(name: name) or raise StandardError, "Cannot find asset #{name.inspect}"
  step %Q{#{pre} asset "#{asset.id}"#{post}}
end

Given /^(.+) the (\w+) asset of the asset "([^\"]+)"(.*)$/ do |pre, relation, id, post|
  asset = Asset.find(id)
  related = asset.send(relation)

  step %Q{#{pre} the asset "#{related.id}"#{post}}
end
