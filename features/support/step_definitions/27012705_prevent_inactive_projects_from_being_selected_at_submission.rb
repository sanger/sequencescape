# frozen_string_literal: true

Given /^I have an inactive project called "([^"]*)"$/ do |project_name|
  project = FactoryBot.create :project, name: project_name
  project.update(state: 'pending')
end
