Given /^an unreleasable lane named "([^"]*)" exists$/ do |name|
  Factory(:lane, :name => name, :external_release => false)
end

Given /^a releasable lane named "([^"]*)" exists$/ do |name|
  Factory(:lane, :name => name, :external_release => true)
end
