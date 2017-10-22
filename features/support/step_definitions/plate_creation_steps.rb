# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2014,2015 Genome Research Ltd.

Transform /^the plate creation with ID (\d+)$/ do |id|
  PlateCreation.find(id)
end

Given /^the UUID for the (parent|child) plate of (the (?:plate|tube) creation with ID \d+) is "([^"]*)"$/ do |plate, plate_creation, uuid_value|
  set_uuid_for(plate_creation.send(plate), uuid_value)
end

Given /^the UUID for the child (?:plate|tube) purpose of (the (?:plate|tube) creation with ID \d+) is "([^"]*)"$/ do |creation, uuid_value|
  set_uuid_for(creation.child_purpose, uuid_value)
end

Then /^the child plate of the last plate creation is a child of the parent plate$/ do
  plate_creation = PlateCreation.last or raise StandardError, 'There are no plate creation instances'
  assert plate_creation.parent.children.all.include?(plate_creation.child), 'Child of the last plate creation is not a child of the parent'
end

Transform /^the tube creation with ID (\d+)$/ do |id|
  TubeCreation.find(id)
end

Given /^the UUID for the child tube of (the tube creation with ID \d+) is "([^"]*)"$/ do |tube_creation, uuid_value|
  set_uuid_for(tube_creation.children.first, uuid_value)
end

Then /^the tubes of the last tube creation are children of the parent plate$/ do
  tube_creation = TubeCreation.last or raise StandardError, 'There are no tube creation instances'
  assert(!tube_creation.children.empty?, 'There are no children in the tube creation')
  assert(tube_creation.children.all?(&tube_creation.parent.children.method(:include?)), 'Children of the last tube creation are not children of the parent')
end
