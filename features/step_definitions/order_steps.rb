Given /^no order templates exist$/ do
  SubmissionTemplate.destroy_all
end

Given /^the order with UUID "([^\"]+)" is for (\d+) "([^\"]+)" requests$/ do |uuid, count, name|
  order = Uuid.with_external_id(uuid).first.try(:resource) or raise StandardError, "Could not find order with UUID #{uuid.inspect}"
  request_type = RequestType.find_by_name(name) or raise StandardError, "Could not find request type #{name.inspect}"
  order.request_options[:multiplier] ||= {}
  order.request_options[:multiplier][request_type.id] = count
  order.save!
end

Given /^I have an order created with the following details based on the template "([^\"]+)":$/ do |name, details|
  template = SubmissionTemplate.find_by_name(name) or raise StandardError, "Cannot find submission template #{name.inspect}"
  order_attributes = details.rows_hash.map do |k,v|
    v =
      case k
      when 'asset_group_name' then v
      when 'request_options' then Hash[v.split(',').map { |p| p.split(':').map(&:strip) }]
      when 'assets' then Uuid.lookup_many_uuids(v.split(',').map(&:strip)).map(&:resource)
      else Uuid.include_resource.lookup_single_uuid(v).resource
      end
    [ k.to_sym, v ]
  end

  order = template.create_order!({ :user => User.first }.merge(Hash[order_attributes]))
end

Given /^an order template with UUID "([^"]+)" exists$/ do |uuid_value|
  set_uuid_for(Factory(:order_template), uuid_value)
end

Given /^an order template called "([^\"]+)" with UUID "([^"]+)"$/ do |name, uuid_value|
  set_uuid_for(Factory(:order_template, :name => name), uuid_value)
end

Given /^the UUID for the order template "([^\"]+)" is "([^\"]+)"$/ do |name,uuid_value|
  object = SubmissionTemplate.find_by_name(name) or raise "Cannot find order template #{ name.inspect }"
  set_uuid_for(object, uuid_value)
end

Then /^the (string |)request options for the order with UUID "([^\"]+)" should be:$/ do |string,uuid, options_table|
  order = Uuid.with_external_id(uuid).first.try(:resource) or raise StandardError, "Could not find order with UUID #{uuid.inspect}"
  options_table.rows_hash.each do |k,v|
    opt = string==("string ") ? k : k.to_sym
    assert_equal(v, order.request_options[opt].to_s, "Request option #{k.inspect} is unexpected")
  end
end

When /^the order with UUID "([^"]*)" has been added to a submission$/ do |uuid|
  order = Uuid.with_external_id(uuid).first.try(:resource) or raise StandardError, "Could not find order with UUID #{uuid.inspect}"
  Submission.create!(:orders => [ order ], :user => order.user )
end

