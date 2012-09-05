Given /^I have a tag instance called "([^\"]+)"$/ do |name|
  Factory(:tag_instance, :name => name)
end

Given /^I have a hybridization spiked buffer called "([^\"]+)"$/ do |name|
  Factory(:spiked_buffer, :name => name)
end
Given /^I have a tag called "([^\"]+)"$/ do |name|
  Factory(:tag, :map_id=> name)
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
  asset = Asset.find_by_name(name) or raise StandardError, "Cannot find asset #{name.inspect}"
  Then %Q{#{pre} asset "#{asset.id}"#{post}}
end

Given /^(.+) the (\w+) asset of the asset "([^\"]+)"(.*)$/ do |pre,relation, id, post|
  asset  = Asset.find(id)
  related = asset.send(relation)

  Then %Q{#{pre} the asset "#{related.id}"#{post}}

end

