Given /^I have a project called "([^\"]*)"$/ do |project|
#  proj = Factory :project_with_order, :name => project
  Factory(:project, :name => project)
end

Given /^project "([^\"]*)" approval is "([^\"]*)"$/ do |project, approval|
  proj = Project.find_by_name(project)
  approval == "approved" ? proj.approved = true : proj.approved = false
  proj.save
end

Given /^I have an "([^\"]*)" project called "([^\"]*)"$/ do |approval, project|
  Given "I have a project called \"#{project}\""
  And "project \"#{project}\" approval is \"#{approval}\""
end

Given /^I have (\d+) "([^\"]+)" projects based on "([^\"]+)" with enough quotas$/ do |count, approval, name|
  (1..count.to_i).each do |index|
    Given %Q{I have an "#{approval}" project called "#{name}-#{index}"}
    Given %Q{project "#{name}-#{index}" has enough quotas}
  end
end

Given /^project "([^\"]*)" has enough quotas$/ do |project|
  proj = Project.find_by_name(project)
  req_types = {}
  RequestType.all.each {|rt| req_types["#{rt.id}"] = 500}
  proj.add_quotas(req_types)
  proj.save
end

Given /^project "([^\"]*)" has enforced quotas$/ do |name|
  project = Project.find_by_name(name) or raise StandardError, "Cannot find project with name #{ name.inspect }"
  project.update_attributes!(:enforce_quotas => true)
end

Given /^project "([^\"]+)" has no quotas$/ do |name|
  project = Project.find_by_name(name) or raise StandardError, "Cannot find project with name #{ name.inspect }"
  project.quotas.clear
end

Given /^project "([^\"]+)" has (\d+) units of "([^\"]+)" quota$/ do |project_name, units, request_type_name|
  project = Project.find_by_name(project_name) or raise StandardError, "Cannot find project with name #{ project_name.inspect }"
  request_type = RequestType.find_by_name(request_type_name) or raise StandardError, "Cannot find request type #{request_type_name.inspect}"
  project.add_quotas(request_type.id.to_s => units.to_i)
end

Given /^the project "([^\"]*)" has quotas and quotas are enforced$/ do |project|
  Given %Q(project "#{project}" has enough quotas)
  Given %Q(project "#{project}" has enforced quotas)
end

Given /^last submission is processed$/ do
  Given %Q{1 pending delayed jobs are processed}
end

Given /^the project quotas table should be:$/ do |expected_table|
  actual_table = tableish('table#summary tr', 'td,th')
  expected_table.diff!(actual_table)
end

Given /^the project "([^\"]+)" has an active study called "([^\"]+)"$/ do |project_name, study_name|
  Given %Q{I have an "active" study called "#{ study_name }"}

  project = Project.find_by_name(project_name) or raise StandardError, "Cannot find project #{ project_name.inspect }"
  study   = Study.find_by_name(study_name) or raise StandardError, "Cannot find study #{ study_name.inspect }"
  project.studies << study
end

Then /^I should see the project information:$/ do |expected_table|
  expected_table.diff!(page.all(:xpath, '//div[@class="project_information"]//td').map(&:text).map(&:strip).in_groups_of(2))
end

Given /^the project "([^\"]*)" a budget division "([^\"]*)"$/ do |project_name, budget_division_name|
  project = Project.find_by_name(project_name) or raise StandardError, "Cannot find project #{ project_name.inspect }"
  budget_division = BudgetDivision.find_by_name(budget_division_name ) or raise StandardError, "Cannot find budget division #{ budget_division_name.inspect }"

  project.update_attributes!(:project_metadata_attributes => {
    :budget_division  => budget_division
  })
end

Given /^the preordered quota for project "([^\"]*)" should be:/ do |project_name, table|
  project = Project.find_by_name(project_name) or raise StandardError, "Cannot find project #{ project_name.inspect }"

  # This little hack is to fix hash ordering in up to date versions of
  # ruby.
  # It's not needed with up to date versions of cucumber... :)

  # table.rows.each do |rt_name ,count |
    table.hashes.map do |hash|
      hash.values_at *table.headers
    end.each do |rt_name,count|

    rt = RequestType.find_by_name(rt_name) or raise RuntimeError, "Cannot find request_type '#{rt_name}'"
    quota = project.quota_for(rt)
    assert_equal count.to_i, quota.preordered_count
  end

end
