Given /^data are preloaded from "([^\"]+)"$/ do |file_name|
  object_parameters = YAML::load(File.read("data/#{file_name}_setup.yml"))
  object_parameters.each do |parameter|
    klass = parameter[:class].constantize
    object_id = parameter[:id]
    attributes = parameter[:attributes]
    object = klass.new(attributes) { |r| r.id = object_id }
    object.save_without_validation
  end
end
