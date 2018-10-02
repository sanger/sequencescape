Then /^log "([^\"]+)" for debugging$/ do |message|
  Rails.logger.debug("#{('=' * 19)} #{message} #{('=' * 19)}")
end

Then /^launch the debugger$/ do
  binding.pry
  puts
end

Then /^debug the javascript$/ do
  p page.driver.network_traffic
  page.driver.debug
end

Then /^stop$/ do
  step 'show me the page'
  step 'launch the debugger'
end
