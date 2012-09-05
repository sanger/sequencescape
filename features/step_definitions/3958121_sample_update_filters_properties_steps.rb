Given /^the workflow named "([^\"]+)" exists$/ do |name|
  Factory(:submission_workflow, :name => name) or raise StandardError, "Cannot create workflow '#{ name }'"
end

Given /^I am the owner of sample "([^\"]+)"$/ do |name|
  sample = Sample.first(:conditions => { :name => name }) or raise StandardError, "Sample '#{ name }' does not exist"
  @current_user.is_owner_of(sample)
end

Given /^I have no associated workflow$/ do
  @current_user.update_attribute(:workflow_id, nil)
  @current_user.reload
end

Given /^I have an associated workflow "([^\"]+)"$/ do |name|
  workflow = Submission::Workflow.first(:conditions => { :name => name }) or raise StandardError, "Workflow '#{ name }' does not exist"
  @current_user.update_attribute(:workflow_id, workflow.id)
  @current_user.reload
end

Given /^the field labeled "([^\"]+)" should not exist$/ do |field_name|
  # begin

    assert_nil field_labeled(field_name), "Field labeled '#{ field_name }' found!"
  # rescue Webrat::NotFoundError => exception
    # Cool, let this pass
  # end
end

Given /^I am an administrator$/ do
  @current_user.roles.create!(:name => 'administrator')
  @current_user.reload
end

# TODO[xxx]: table cells don't appear to play nicely!
Then /^I should see "([^\"]+)" set to "([^\"]+)"$/ do |property_name,value|
  Then %Q{I should see "#{ property_name }"}
  Then %Q{I should see "#{ value }"}
end

Then /^I should not see "([^\"]+)" set to "([^\"]+)"$/ do |property_name,value|
  Then %Q{I should not see "#{ property_name }"}
  Then %Q{I should not see "#{ value }"}
end
