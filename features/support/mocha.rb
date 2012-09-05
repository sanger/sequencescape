# This file is here to ensure that the mock objects get cleared down properly after each scenario.
require "mocha"

World(Mocha::API)

Before do
  mocha_setup
end

After do
  begin
    mocha_verify
  ensure
    mocha_teardown
  end
end

