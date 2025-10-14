# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.config.content_security_policy do |policy|
  # policy.default_src :self, :https
  # policy.font_src    :self, :https, :data
  # policy.img_src     :self, :https, :data
  # policy.object_src  :none
  # policy.script_src  :self, :https
  # policy.style_src   :self, :https
  # Specify URI for violation reports
  # policy.report_uri "/csp-violation-report-endpoint"

  # Snippet provided after running
  # `bundle exec rails webpacker:install:vue`
  # > You need to enable unsafe-eval rule.
  # > This can be done in Rails 5.2+ for development environment in the CSP initializer
  # > config/initializers/content_security_policy.rb with a snippet like this:
  if Rails.env.development?
    # Also allow @vite/client to hot reload javascript changes in development
    policy.script_src :self, :https, :unsafe_eval, "http://#{ViteRuby.config.host_with_port}"
  else
    policy.script_src :self, :https
  end

  # You may need to enable this in production as well depending on your setup.
  policy.script_src(*policy.script_src, :blob) if Rails.env.test?

  #   policy.style_src   :self, :https
  # Allow @vite/client to hot reload style changes in development
  policy.style_src(:self, :https, :unsafe_inline) if Rails.env.development?

  # Allow @vite/client to hot reload changes in development
  policy.connect_src(:self, "ws://#{ViteRuby.config.host_with_port}") if Rails.env.development?

  #   # Specify URI for violation reports
  #   # policy.report_uri "/csp-violation-report-endpoint"
end

# If you are using UJS then enable automatic nonce generation
Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
Rails.application.config.content_security_policy_nonce_directives = %w[script-src]

# Set the nonce only to specific directives
# Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Report only for now because we have some inline JS that can't use nonce values e.g. inline onclick event handlers
# (see ajax_handling.js for an example)
Rails.application.config.content_security_policy_report_only = true
