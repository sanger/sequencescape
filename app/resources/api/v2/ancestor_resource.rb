# frozen_string_literal: true
module Api
  module V2
    # Provides a JSON API representation of Ancestor
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class AncestorResource < LabwareResource
      filter :purpose_name
    end
  end
end
