Given /^there is a plate purpose named "([^\"]+)"$/ do |name|
  PlatePurpose.first(:conditions => { :name => name })
end

Then /^the "([^\"]+)" fields listed below should be appropriately displayed:$/ do |workflow_name,table|
  table.hashes.each do |details|
    begin
      # TODO: Newer versions of Capybara raise an exception
      element = page.find_field(details['field']) or raise Capybara::ElementNotFound, "Found #{ details['field'].inspect }"
      assert(details['workflow'] == workflow_name, "The field #{details['field'].inspect} should not exist for #{workflow_name.inspect}")
    rescue Capybara::ElementNotFound => exception
      assert(details['workflow'] != workflow_name, "The field #{details['field'].inspect} should exist for #{workflow_name.inspect}")
    end
  end
end
