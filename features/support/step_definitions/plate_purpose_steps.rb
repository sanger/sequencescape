# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2014,2015 Genome Research Ltd.

Given /^a (plate|tube) purpose "([^"]+)" with UUID "([^"]+)"$/ do |type, name, uuid_value|
  set_uuid_for(FactoryGirl.create("#{type}_purpose", name: name), uuid_value)
end

Transform /^the plate purpose "([^\"]+)"$/ do |name|
  PlatePurpose.find_by(name: name) or raise StandardError, "Cannot find plate purpose #{name.inspect}"
end

Transform /^the purpose "([^\"]+)"$/ do |name|
  Purpose.find_by(name: name) or raise StandardError, "Cannot find purpose #{name.inspect}"
end

Given /^(the plate purpose "[^"]+") is a parent of (the plate purpose "[^"]+")$/ do |parent, child|
  parent.child_relationships.create!(child: child, transfer_request_type: RequestType.transfer)
end

Given /^(the purpose "[^"]+") is a parent of (the purpose "[^"]+")$/ do |parent, child|
  parent.child_relationships.create!(child: child, transfer_request_type: RequestType.transfer)
end

When /^"(.*?)" plate purpose picks with "(.*?)"$/ do |name, filter|
  purpose = PlatePurpose.find_by(name: name)
  purpose.cherrypick_filters << filter unless purpose.cherrypick_filters.include?(filter)
  purpose.save!
end
