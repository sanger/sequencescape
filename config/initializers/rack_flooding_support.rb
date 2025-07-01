# frozen_string_literal: true
# Rack 1.1.3 introduced flooding protection support that needs to be significantly higher for our environment.
# This multiplier is completely arbitrary as we have no rogue clients, except maybe our users!
# In Rack 3.0 and later, Rack::Utils.key_space_limit and its setter no longer exist.
# To ensure compatibility with both Rack 2.x and Rack 3.x, we check for the existence of the methods
if Rack::Utils.respond_to?(:key_space_limit) && Rack::Utils.respond_to?(:key_space_limit=)
  Rack::Utils.key_space_limit = Rack::Utils.key_space_limit * 20
elsif Rack.respond_to?(:set_key_space_limit) && Rack.respond_to?(:key_space_limit)
  Rack.set_key_space_limit(Rack.key_space_limit * 20)
end
