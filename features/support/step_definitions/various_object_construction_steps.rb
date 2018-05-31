# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2015 Genome Research Ltd.

Given /^(?:a|the) (project|study|sample|sample tube|library tube|plate|lane|pulldown multiplexed library tube|multiplexed library tube|faculty sponsor) (?:named|called) "([^\"]+)" exists$/ do |type, name|
  FactoryGirl.create(type.gsub(/[^a-z0-9]+/, '_').to_sym, name: name)
end

Given /^(?:a|the) (well) (?:named|called) "([^\"]+)" exists$/ do |type, _|
  FactoryGirl.create(type.gsub(/[^a-z0-9]+/, '_').to_sym)
end
