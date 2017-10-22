# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

Given /^(the plate .+) is in the "([^\"]+)" freezer$/ do |plate, freezer|
  location = Location.find_by(name: freezer) or raise "Cannot find the freezer #{freezer.inspect}"
  plate.update_attributes!(location: location)
end
