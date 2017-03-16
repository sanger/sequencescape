# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

Given /^a state "([^"]*)" to lane named "([^"]*)"$/ do |status, name|
  FactoryGirl.create(:lane, name: name, qc_state: status)
end

Given /^an unreleasable lane named "([^"]*)"$/ do |name|
  lane = Lane.find_by(name: name)
  lane.external_release = false
  lane.save
end

Given /^an releasable lane named "([^"]*)"$/ do |name|
  lane = Lane.find_by(name: name)
  lane.external_release = true
  lane.save
end
