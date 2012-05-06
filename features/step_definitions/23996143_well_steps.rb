Given /^the nameless well exists with ID (\d+)$/ do |id|
  Factory(:nameless_well, :id => id)
end
