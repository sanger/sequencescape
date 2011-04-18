Given /^data are preloaded from "([^\"]+)" renaming:$/ do |file_name, table|
  names_map = {}
  table.rows.each do |old_name, new_name|
    names_map[old_name]= new_name
  end
  object_parameters = YAML::load(File.read("data/setup/#{file_name}.yml"))
  object_parameters.each do |parameter|
    klass = parameter[:class].constantize
    object_id = parameter[:id]
    attributes = parameter[:attributes]
    if name=attributes["name"]
      attributes["name"] = names_map.fetch(name, name)
    end
    object = klass.new(attributes) { |r| r.id = object_id }
    object.save_without_validation
  end
end
Given /^data are preloaded from "([^\"]+)"$/ do |file_name|
  Given %Q{data are preloaded from "#{file_name}" renaming:}
end
