Then /^log "([^\"]+)" for debugging$/ do |message|
  Rails.logger.debug("#{('=' * 19)} #{message} #{('=' * 19)}")
end

Then /^launch the debugger$/ do
  debugger
  puts
end

Then /^stop$/ do
  step %q{show me the page}
  step %q{launch the debugger}
end
