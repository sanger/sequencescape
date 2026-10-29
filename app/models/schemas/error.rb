# frozen_string_literal: true

# The parent of the errors raised when a schema can't be loaded or used, so
# callers can rescue them all, and only them.
class Schemas::Error < StandardError
end
