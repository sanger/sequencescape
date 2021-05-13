# frozen_string_literal: true

# This file is here to ensure that the mock objects get cleared down properly after each scenario.
require 'mocha/api'

World(Mocha::API)

Before() { mocha_setup }

After() do
  mocha_verify
ensure
  mocha_teardown
end
