# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :none
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https, :data
    policy.style_src   :self, :https
    policy.connect_src :self, :https

   # Specify URI for violation reports
    policy.report_uri "/csp-reports"
  end

   # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w(script-src style-src)

  # Nonces are also required for Vite resources tags:
  # See ViteRailsNoncePatch at config/initializers/vite_rails_nonce_patch.rb for more information.

  # Report CSP violations to a specified URI
  # For further information see the following documentation:
  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
  # Report only for now because we have some inline JS that can't use nonce values e.g. inline onclick event handlers
  # (see ajax_handling.js for an example)
  #   Report violations without enforcing the policy.
  config.content_security_policy_report_only = true
end
