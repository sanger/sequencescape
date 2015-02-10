#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2013,2015 Genome Research Ltd.
Given /^(?:a|the) (project|study|sample|sample tube|library tube|plate|lane|pulldown multiplexed library tube|multiplexed library tube|faculty sponsor) (?:named|called) "([^\"]+)" exists$/ do |type,name|
  Factory(type.gsub(/[^a-z0-9]+/, '_').to_sym, :name => name)
end

Given /^(?:a|the) (well) (?:named|called) "([^\"]+)" exists$/ do |type,_|
  Factory(type.gsub(/[^a-z0-9]+/, '_').to_sym )
end

Given /^(?:a|the) properly created ((?:multiplexed )?library tube) (?:named|called) "([^\"]+)" exists$/ do |type, name|
  Factory(:"full_#{type.gsub(/[^a-z0-9]+/, '_')}", :name => name)
end

Given /^(?:an|the) improperly created ((?:multiplexed )?library tube) (?:named|called) "([^\"]+)" exists$/ do |type, name|
  Factory(:"broken_#{type.gsub(/[^a-z0-9]+/, '_')}", :name => name)
end

Given /^an (item) named "([^\"]+)" exists$/ do |type,name|
  Factory(type.gsub(/[^a-z0-9]+/, '_').to_sym, :name => name)
end

