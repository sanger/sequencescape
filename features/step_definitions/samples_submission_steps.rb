Given /^exist a Samples called "([^\"]*)"$/ do |nameSample|
  s = Factory :sample, :name => nameSample
end
