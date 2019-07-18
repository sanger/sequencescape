# frozen_string_literal: true

Given /^I have a hybridization spiked buffer called "([^\"]+)"$/ do |name|
  buffer = FactoryBot.create(:spiked_buffer, name: name)
  buffer.parents << FactoryBot.create(:phi_x_stock_tube, name: 'indexed phiX')
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
