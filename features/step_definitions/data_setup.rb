Given /^data are preloaded from "([^\"]+)"$/ do |file_name|
  require "data/#{file_name}_setup"
end
