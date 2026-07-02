# frozen_string_literal: true
# This class is used to store the current API application for the duration of a request,
# so that it can be accessed in models and other places where the controller context is not available.

class Current < ActiveSupport::CurrentAttributes
  attribute :api_application
end
