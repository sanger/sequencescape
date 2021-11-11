# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.config.content_security_policy do |policy|
  #   policy.default_src :self, :https
  #   policy.font_src    :self, :https, :data
  #   policy.img_src     :self, :https, :data
  #   policy.object_src  :none
  #   policy.script_src  :self, :https
  #   policy.style_src   :self, :https

  #   # If you are using webpack-dev-server then specify webpack-dev-server host
  #   policy.connect_src :self, :https, "http://localhost:3035", "ws://localhost:3035" if Rails.env.development?

  #   # Specify URI for violation reports
  #   # policy.report_uri "/csp-violation-report-endpoint"

  # Snippet provided after running
  # `bundle exec rails webpacker:install:vue`
  # > You need to enable unsafe-eval rule.
  # > This can be done in Rails 5.2+ for development environment in the CSP initializer
  # > config/initializers/content_security_policy.rb with a snippet like this:
  if Rails.env.development?
    policy.script_src :self, :https, :unsafe_eval
  else
    policy.script_src :self, :https
  end
end

# If you are using UJS then enable automatic nonce generation
Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }

# Set the nonce only to specific directives
# Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
Rails.application.config.content_security_policy_report_only = true
