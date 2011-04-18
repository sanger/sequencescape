Given /^Pipeline "([^"]*)" and a setup for 641709$/ do |name|
 pipeline = Pipeline.find_by_name(name) or raise StandardError, "Cannot find pipeline '#{ name }'"
 pipeline.workflow.item_limit.times do
   Given %Q{I have a request for "#{name}"}
 end
end

When /^I select eight requests$/ do
  Request.all(:limit => 8, :order => 'id desc').each do |request|
    When %Q{I check "Select #{request.asset.sti_type} #{request.asset.barcode} for batch"}
  end
end
