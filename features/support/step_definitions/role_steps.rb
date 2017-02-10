# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

Given /^I have administrative role$/ do
  @current_user.is_administrator
end

Given /^I have lab role$/ do
  @current_user.is_lab
end

Given /^I have lab manager role$/ do
  @current_user.is_lab_manager
end

Given /^the role "([^"]*)" exists$/ do |role_name|
  Role.create!(name: role_name.tr(' ', '_').downcase)
end

Given /^user "([^\"]+)" is an administrator$/ do |login|
  user = User.find_by(login: login) or raise StandardError, "Cannot find user with login #{login.inspect}"
  user.roles.create!(name: 'administrator')
end

Given /^user "([^\"]+)" is a manager of "([^\"]+)"$/ do |login, name|
  user  = User.find_by(login: login) or raise StandardError, "Cannot find user with login #{login.inspect}"
  study = Study.find_by(name: name) or raise StandardError, "Cannot find study #{name.inspect}"
  user.has_role('manager', study)
end
