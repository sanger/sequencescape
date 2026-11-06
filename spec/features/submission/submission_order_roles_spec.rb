# frozen_string_literal: true

require 'rails_helper'

# The source feature submission_order_roles.feature has a Background only:
# frozen time, API cookie/SSO/application, study/project UUIDs, a 96-well plate,
# and queued UUIDs for the next submission/order. It has NO Scenario or outline.
# Cucumber therefore never executes that background. Do not invent an API/UI
# action or a passing example claiming to test order roles; there is no source
# behaviour to migrate. Retain this explicit marker pending a real scenario.
