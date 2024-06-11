# frozen_string_literal: true

Given /^user "([^"]*)" owns all requests$/ do |user_name|
  user = FactoryBot.create :user, login: user_name
  Request.find_each { |request| request.update!(user:) }
end

Given /^all requests have a priority flag$/ do
  Request.find_each do |request|
    request.update!(priority: 1)
    request.submission.create!(user: User.last) if request.submission.blank?
    request.submission.update!(priority: 1)
  end
end
