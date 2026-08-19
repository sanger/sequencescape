# frozen_string_literal: true

# Controller to handle Content Security Policy violation reports sent by browsers.
#
# These reports are sent as JSON payloads to the specified report URI when a CSP violation occurs.
# The controller logs the received reports for further analysis and debugging.
#
# For more details, see https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Content-Security-Policy/report-to
class ContentSecurityPolicyReportsController < ApplicationController
  skip_before_action :login_required

  # Record violation reports in the application logs
  def create
    Rails.logger.warn "[csp-report] #{request.body.read}"

    # Respond with a 204 No Content to acknowledge receipt of the report
    head :no_content
  end
end
