# frozen_string_literal: true

Given /^I have a project called "([^"]*)"$/ do |project|
  #  proj = FactoryBot.create :project_with_order, :name => project
  FactoryBot.create(:project, name: project)
end

Given /^a project named "([^"]*)" with project cost code "([^"]*)"$/ do |project_name, cost_code|
  project = FactoryBot.create(:project, name: project_name)
  project.project_metadata.update!(project_cost_code: cost_code)
end

Given /^project "([^"]*)" approval is "([^"]*)"$/ do |project, approval|
  proj = Project.find_by(name: project)
  proj.approved = (approval == 'approved')
  proj.save
end

Given /^I have an "([^"]*)" project called "([^"]*)"$/ do |approval, project|
  step "I have a project called \"#{project}\""
  step "project \"#{project}\" approval is \"#{approval}\""
end

Given /^project "([^"]*)" has enforced quotas$/ do |name|
  project = Project.find_by(name:) or raise StandardError, "Cannot find project with name #{name.inspect}"
  project.update!(enforce_quotas: true)
end

Then /^I should see the project information:$/ do |expected_table|
  expected_table.diff!(
    page.all(:xpath, '//div[@class="project_information"]//td').map(&:text).map(&:strip).in_groups_of(2)
  )
end

Given /^the project "([^"]*)" a budget division "([^"]*)"$/ do |project_name, budget_division_name|
  project = Project.find_by(name: project_name) or raise StandardError, "Cannot find project #{project_name.inspect}"
  budget_division = BudgetDivision.find_by(name: budget_division_name) or
    raise StandardError, "Cannot find budget division #{budget_division_name.inspect}"

  project.update!(project_metadata_attributes: { budget_division: })
end
