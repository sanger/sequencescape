Transform /the plate creation with ID (\d+)/ do |id|
  PlateCreation.find(id)
end

Given /^the UUID for the (parent|child) plate of (the plate creation with ID \d+) is "([^"]*)"$/ do |plate, plate_creation, uuid_value|
  set_uuid_for(plate_creation.send(plate), uuid_value)
end

Given /^the UUID for the child plate purpose of (the plate creation with ID \d+) is "([^"]*)"$/ do |plate_creation, uuid_value|
  set_uuid_for(plate_creation.child_plate_purpose, uuid_value)
end

Then /^the child plate of the last plate creation is a child of the parent plate$/ do
  plate_creation = PlateCreation.last or raise StandardError, "There are no plate creation instances"
  assert plate_creation.parent.children.all.include?(plate_creation.child), "Child of the last plate creation is not a child of the parent"
end
