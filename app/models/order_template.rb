# frozen_string_literal: true
# SubmissionTemplate is really OrderTemplate, and the only place that actually cares is the API, so alias
# If we remove this, then we break our API endpoints. Some of which, at least at one point, actually had
# external users.
OrderTemplate = SubmissionTemplate

# TODO: {API v1 removal} this alias was created for v1 and should not be in v2. When v1 is removed, we should try
#       to remove this alias as well.
