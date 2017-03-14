# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

Given /^I have a project called "([^\"]*)"$/ do |project|
  #  proj = FactoryGirl.create :project_with_order, :name => project
  FactoryGirl.create(:project, name: project)
end

Given /^project "([^\"]*)" approval is "([^\"]*)"$/ do |project, approval|
  proj = Project.find_by(name: project)
  proj.approved = (approval == 'approved' ? true : false)
  proj.save
end

Given /^I have an "([^\"]*)" project called "([^\"]*)"$/ do |approval, project|
  step "I have a project called \"#{project}\""
  step "project \"#{project}\" approval is \"#{approval}\""
end

Given /^project "([^\"]*)" has enforced quotas$/ do |name|
  project = Project.find_by(name: name) or raise StandardError, "Cannot find project with name #{name.inspect}"
  project.update_attributes!(enforce_quotas: true)
end

Given /^last submission is processed$/ do
  step('1 pending delayed jobs are processed')
end

Given /^the project "([^\"]+)" has an active study called "([^\"]+)"$/ do |project_name, study_name|
  step(%Q{I have an "active" study called "#{study_name}"})

  project = Project.find_by(name: project_name) or raise StandardError, "Cannot find project #{project_name.inspect}"
  study   = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  project.studies << study
end

Then /^I should see the project information:$/ do |expected_table|
  expected_table.diff!(page.all(:xpath, '//div[@class="project_information"]//td').map(&:text).map(&:strip).in_groups_of(2))
end

Given /^the project "([^\"]*)" a budget division "([^\"]*)"$/ do |project_name, budget_division_name|
  project = Project.find_by(name: project_name) or raise StandardError, "Cannot find project #{project_name.inspect}"
  budget_division = BudgetDivision.find_by(name: budget_division_name) or raise StandardError, "Cannot find budget division #{budget_division_name.inspect}"

  project.update_attributes!(project_metadata_attributes: {
    budget_division: budget_division
  })
end
