# frozen_string_literal: true

# Deprecating a search
# - Update the existing class to inherit from this
# - Push out a release
# - Update the existing class records to use this class directly
# - Remove the original class in a subsequent release
class Search::DeprecatedSearch < Search
  def scope(_)
    raise ::Core::Service::DeprecatedAction
  end
end
