# frozen_string_literal: true
# Rack 1.1.3 introduced flooding protection support that needs to be significantly higher for our environment.
# This multiplier is completely arbitrary as we have no rogue clients, except maybe our users!
Rack::Utils.key_space_limit = Rack::Utils.key_space_limit * 20
