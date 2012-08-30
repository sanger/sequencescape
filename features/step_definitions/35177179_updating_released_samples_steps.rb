Given /^the sample name "([^"]*)" has previously been released$/ do |name|
  Sample.find_by_name(name).release
end
