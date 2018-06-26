
Transform /^the plate purpose "([^\"]+)"$/ do |name|
  PlatePurpose.find_by(name: name) or raise StandardError, "Cannot find plate purpose #{name.inspect}"
end

Transform /^the purpose "([^\"]+)"$/ do |name|
  Purpose.find_by(name: name) or raise StandardError, "Cannot find purpose #{name.inspect}"
end
