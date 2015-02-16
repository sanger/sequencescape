#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
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
