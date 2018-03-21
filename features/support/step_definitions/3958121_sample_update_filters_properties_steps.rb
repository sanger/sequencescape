# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

Given /^I am the owner of sample "([^\"]+)"$/ do |name|
  sample = Sample.find_by!(name: name)
  @current_user.is_owner_of(sample)
end

Given /^I am an administrator$/ do
  @current_user.roles.create!(name: 'administrator')
  @current_user.reload
end

# TODO[xxx]: table cells don't appear to play nicely!
Then /^I should see "([^\"]+)" set to "([^\"]+)"$/ do |property_name, value|
  step %Q{I should see "#{property_name}"}
  step %Q{I should see "#{value}"}
end
