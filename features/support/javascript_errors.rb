# frozen_string_literal: true

# Possible values are :truncation and :transaction
# The :transaction strategy is faster, but might give you threading problems.
# See https://github.com/cucumber/cucumber-rails/blob/master/features/choose_javascript_database_strategy.feature
Cucumber::Rails::Database.javascript_strategy = :transaction

World(MultiTest::MinitestWorld)
MultiTest.disable_autorun

After() do |scenario|
  if scenario.failed?
    name = scenario.name.parameterize
    CapybaraFailureLogger.log_failure(name, page) { |message| warn message }
  end
end
Cucumber::Rails::Database.javascript_strategy = :truncation
