Given /^I have a batch in "([^\"]*)" with state released$/ do |pipeline|
  @batch = Factory :batch, :pipeline => Pipeline.find_by_name(pipeline), :state => "released",  :production_state => nil
end
