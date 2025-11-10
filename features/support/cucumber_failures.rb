# frozen_string_literal: true

After() do |scenario|
  if scenario.failed?
    name = scenario.name.parameterize
    CapybaraFailureLogger.log_failure(name, page) { |message| warn message }
  end
end
