# frozen_string_literal: true

Given /^I have an order created with the following details based on the template "([^"]+)":$/ do |name, details|
  template = SubmissionTemplate.find_by(name:) or raise StandardError, "Cannot find submission template #{name.inspect}"
  order_attributes =
    details.rows_hash.map do |k, v|
      v =
        case k
        when 'asset_group_name'
          v
        when 'request_options'
          v.split(',').to_h { |p| p.split(':').map(&:strip) }
        when 'assets'
          Uuid.lookup_many_uuids(v.split(',').map(&:strip)).map(&:resource)
        when 'pre_cap_group'
          v
        else
          Uuid.include_resource.lookup_single_uuid(v).resource
        end
      [k.to_sym, v]
    end
  user = User.find_by(login: 'abc123') || FactoryBot.create(:user, login: 'abc123')
  order = template.create_order!({ user: }.merge(order_attributes.to_h))
end

Given /^an order template called "([^"]+)" with UUID "([^"]+)"$/ do |name, uuid_value|
  set_uuid_for(FactoryBot.create(:submission_template, name:), uuid_value)
end

Given /^the UUID for the order template "([^"]+)" is "([^"]+)"$/ do |name, uuid_value|
  object = SubmissionTemplate.find_by!(name:)
  set_uuid_for(object, uuid_value)
end

Then /^the (string |)request options for the order with UUID "([^"]+)" should be:$/ do |_string, uuid, options_table|
  order = Uuid.with_external_id(uuid).first.try(:resource) or
    raise StandardError, "Could not find order with UUID #{uuid.inspect}"

  # rubocop:todo Layout/LineLength
  stringified_options = order.request_options.stringify_keys # Needed because of inconsistencies in keys (symbols & strings)

  # rubocop:enable Layout/LineLength
  options_table.rows_hash.each do |k, v|
    assert_equal(v, stringified_options[k].to_s, "Request option #{k.inspect} is unexpected")
  end
end

When /^the order with UUID "([^"]*)" has been added to a submission$/ do |uuid|
  order = Uuid.with_external_id(uuid).first.try(:resource) or
    raise StandardError, "Could not find order with UUID #{uuid.inspect}"
  Submission.create!(orders: [order], user: order.user)
end
