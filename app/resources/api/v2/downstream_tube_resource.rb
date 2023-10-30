# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of Tube
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class DownstreamTubeResource < BaseResource
      model_name 'Tube'
    end
  end
end
