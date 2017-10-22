# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

Then /^I should see the following autocomplete options:$/ do |table|
  # table is a Cucumber::Ast::Table
  table.raw.each do |_row|
    # page.locate(:xpath, "//a[text()='#{row[0]}']")
    page.has_xpath?('.//a', text: '#{row[0]}')
  end
end

When /^I click on the "([^"]*)" autocomplete option$/ do |link_text|
  page.driver.browser.execute_script %Q{ $('.ui-menu-item a:contains("#{link_text}")').trigger("mouseenter").click(); }
end
