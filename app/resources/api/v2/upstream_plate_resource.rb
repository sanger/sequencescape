# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of Plate
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class UpstreamPlateResource < BaseResource
      model_name 'Plate'
    end
  end
end
