
Transform /^the plate purpose "([^\"]+)"$/ do |name|
  PlatePurpose.find_by(name: name) or raise StandardError, "Cannot find plate purpose #{name.inspect}"
end

Transform /^the purpose "([^\"]+)"$/ do |name|
  Purpose.find_by(name: name) or raise StandardError, "Cannot find purpose #{name.inspect}"
end

When /^"(.*?)" plate purpose picks with "(.*?)"$/ do |name, filter|
  purpose = PlatePurpose.find_by(name: name)
  purpose.cherrypick_filters << filter unless purpose.cherrypick_filters.include?(filter)
  purpose.save!
end
