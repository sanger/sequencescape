# frozen_string_literal: true

require 'webmock/cucumber'
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: ['api.knapsackpro.com', 'messages.cucumber.io', /cucumber-messages-app-/]
)
