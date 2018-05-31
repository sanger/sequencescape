# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2014,2015 Genome Research Ltd.

Given /^user "([^"]*)" owns all requests$/ do |user_name|
  user = FactoryBot.create :user, login: user_name
  Request.find_each do |request|
    request.update_attributes!(user: user)
  end
end

Given /^all requests have a priority flag$/ do
  Request.find_each do |request|
    request.update_attributes!(priority: 1)
    request.submission.create!(user: User.last) unless request.submission.present?
    request.submission.update_attributes!(priority: 1)
  end
end
