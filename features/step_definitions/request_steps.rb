Given /^user "([^"]*)" owns all requests$/ do |user_name|
  user = Factory :user, :login => user_name
  Request.find_each do |request|
    request.update_attributes!(:user => user)
  end
end

Given /^all requests have a priority flag$/ do
  Request.find_each do |request|
    request.update_attributes!(:priority => 1)
    request.submission.create!(:user=>User.last) unless request.submission.present?
    request.submission.update_attributes!(:priority => 1)
  end
end
