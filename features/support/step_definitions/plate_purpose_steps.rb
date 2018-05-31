# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2014,2015 Genome Research Ltd.

Transform /^the plate purpose "([^\"]+)"$/ do |name|
  PlatePurpose.find_by(name: name) or raise StandardError, "Cannot find plate purpose #{name.inspect}"
end

Transform /^the purpose "([^\"]+)"$/ do |name|
  Purpose.find_by(name: name) or raise StandardError, "Cannot find purpose #{name.inspect}"
end

When /^"(.*?)" plate purpose picks with "(.*?)"$/ do |name, filter|
  purpose = PlatePurpose.find_by(name: name)
  purpose.cherrypick_filters << filter unless purpose.cherrypick_filters.include?(filter)
  purpose.save!
end
