Given /^a (plate|tube) purpose "([^"]+)" with UUID "([^"]+)"$/ do |type, name, uuid_value|
  set_uuid_for(Factory("#{type}_purpose", :name => name), uuid_value)
end

Transform /^the plate purpose "([^\"]+)"$/ do |name|
  PlatePurpose.find_by_name(name) or raise StandardError, "Cannot find plate purpose #{name.inspect}"
end

Transform /^the purpose "([^\"]+)"$/ do |name|
  Purpose.find_by_name(name) or raise StandardError, "Cannot find purpose #{name.inspect}"
end

Given /^(the plate purpose "[^"]+") is a parent of (the plate purpose "[^"]+")$/ do |parent, child|
  parent.child_relationships.create!(:child => child, :transfer_request_type => RequestType.transfer)
end

Given /^(the purpose "[^"]+") is a parent of (the purpose "[^"]+")$/ do |parent, child|
  parent.child_relationships.create!(:child => child, :transfer_request_type => RequestType.transfer)
end
