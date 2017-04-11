# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2015,2016 Genome Research Ltd.

Given /^no order templates exist$/ do
  SubmissionTemplate.destroy_all
end

Given /^the order with UUID "([^\"]+)" is for (\d+) "([^\"]+)" requests$/ do |uuid, count, name|
  order = Uuid.with_external_id(uuid).first.try(:resource) or raise StandardError, "Could not find order with UUID #{uuid.inspect}"
  request_type = RequestType.find_by(name: name) or raise StandardError, "Could not find request type #{name.inspect}"
  order.request_options[:multiplier] ||= {}
  order.request_options[:multiplier][request_type.id] = count
  order.save!
end

Given /^I have an order created with the following details based on the template "([^\"]+)":$/ do |name, details|
  template = SubmissionTemplate.find_by(name: name) or raise StandardError, "Cannot find submission template #{name.inspect}"
  order_attributes = details.rows_hash.map do |k, v|
    v =
      case k
      when 'asset_group_name' then v
      when 'request_options' then Hash[v.split(',').map { |p| p.split(':').map(&:strip) }]
      when 'assets' then Uuid.lookup_many_uuids(v.split(',').map(&:strip)).map(&:resource)
      when 'pre_cap_group' then v
      else Uuid.include_resource.lookup_single_uuid(v).resource
      end
    [k.to_sym, v]
  end
  user = User.find_by(login: 'abc123') || FactoryGirl.create(:user, login: 'abc123')
  order = template.create_order!({ user: user }.merge(Hash[order_attributes]))
end

Given /^an order template with UUID "([^"]+)" exists$/ do |uuid_value|
  set_uuid_for(FactoryGirl.create(:submission_template), uuid_value)
end

Given /^an order template called "([^\"]+)" with UUID "([^"]+)"$/ do |name, uuid_value|
  set_uuid_for(FactoryGirl.create(:submission_template, name: name), uuid_value)
end

Given /^the UUID for the order template "([^\"]+)" is "([^\"]+)"$/ do |name, uuid_value|
  object = SubmissionTemplate.find_by!(name: name)
  set_uuid_for(object, uuid_value)
end

Then /^the (string |)request options for the order with UUID "([^\"]+)" should be:$/ do |_string, uuid, options_table|
  order = Uuid.with_external_id(uuid).first.try(:resource) or raise StandardError, "Could not find order with UUID #{uuid.inspect}"
  stringified_options = order.request_options.stringify_keys # Needed because of inconsistencies in keys (symbols & strings)
  options_table.rows_hash.each do |k, v|
    assert_equal(v, stringified_options[k].to_s, "Request option #{k.inspect} is unexpected")
  end
end

When /^the order with UUID "([^"]*)" has been added to a submission$/ do |uuid|
  order = Uuid.with_external_id(uuid).first.try(:resource) or raise StandardError, "Could not find order with UUID #{uuid.inspect}"
  Submission.create!(orders: [order], user: order.user)
end
