Then /^I should see the following autocomplete options:$/ do |table|
  # table is a Cucumber::Ast::Table
  table.raw.each do |row|
    #page.locate(:xpath, "//a[text()='#{row[0]}']")
    page.has_xpath?('.//a', :text => '#{row[0]}')
  end
end

When /^I click on the "([^"]*)" autocomplete option$/ do |link_text|
  page.driver.browser.execute_script %Q{ $('.ui-menu-item a:contains("#{link_text}")').trigger("mouseenter").click(); }
end


