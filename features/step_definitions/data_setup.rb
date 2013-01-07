require 'import_pulled_data'
class NilClass
  def failed?
    true
  end
end
Given /^data are preloaded from "([^\"]+)" renaming:$/ do |file_name, table|
  names_map = Hash[table.rows.map { |n,o| [o,n] }]
  ImportPulledData::import_from_yaml("data/setup/#{file_name}.yml", names_map)
end
Given /^data are preloaded from "([^\"]+)"$/ do |file_name|
  step(%Q{data are preloaded from "#{file_name}" renaming:})
end
