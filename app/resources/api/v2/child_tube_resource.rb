# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of Plate
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class ChildTubeResource < BaseResource
      model_name 'Tube'
    end
  end
end
