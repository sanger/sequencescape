Given /^a plate purpose "([^"]+)" with UUID "([^"]+)"$/ do |name, uuid_value|
  set_uuid_for(Factory(:plate_purpose, :name => name), uuid_value)
end

Transform /^the plate purpose "([^\"]+)"$/ do |name|
  PlatePurpose.find_by_name(name) or raise StandardError, "Cannot find plate purpose #{name.inspect}"
end

Given /^(the plate purpose "[^"]+") is a parent of (the plate purpose "[^"]+")$/ do |parent, child|
  parent.child_plate_purposes << child
end
