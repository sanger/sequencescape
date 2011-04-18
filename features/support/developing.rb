# This is an after filter that will display the page if the scenario fails and is tagged with '@developing'
After('@developing') do |scenario|
  save_and_open_page unless scenario.nil? or scenario.passed?
end

# If the environment is setup correctly then kill Cucumber if any scenario fails.
After do |scenario|
  Cucumber.wants_to_quit = !!(scenario.failed? && ENV['CUCUMBER_MUST_DIE_ASAP'])
end

