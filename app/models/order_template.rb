# frozen_string_literal: true
# SubmissionTemplate is really OrderTemplate, and the only place that actually cares is the API, so alias
# If we remove this, then we break our API endpoints. Some of which, at least at one point, actually had
# external users.
OrderTemplate = SubmissionTemplate
