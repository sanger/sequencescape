require 'import_pulled_data'
class NilClass
  def failed?
    true
  end
end
Given /^data are preloaded from "([^\"]+)" renaming:$/ do |file_name, table|
  names_map = {}
  table.rows.each do |new_name, old_name|
    names_map[old_name]= new_name
  end

  ImportPulledData::import_from_yaml("data/setup/#{file_name}.yml", names_map)
end
Given /^data are preloaded from "([^\"]+)"$/ do |file_name|
  Given %Q{data are preloaded from "#{file_name}" renaming:}
end
