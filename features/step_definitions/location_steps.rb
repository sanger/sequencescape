Given /^(the plate .+) is in the "([^\"]+)" freezer$/ do |plate, freezer|
  location = Location.find_by_name(freezer) or raise "Cannot find the freezer #{freezer.inspect}"
  plate.update_attributes!(:location => location)
end
