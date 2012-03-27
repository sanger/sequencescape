Given /^I have an inactive project called "([^"]*)"$/ do |project_name|
  project = Factory :project, :name => project_name
  project.update_attributes(:state => 'pending')
end
