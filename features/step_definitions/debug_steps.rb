Then /^log "([^\"]+)" for debugging$/ do |message|
  Rails.logger.debug("#{('=' * 19)} #{message} #{('=' * 19)}")
end

Then /^launch the debugger$/ do
  debugger
  puts
end

Then /^stop$/ do
  Then %q{show me the page}
  And %q{launch the debugger}
end
