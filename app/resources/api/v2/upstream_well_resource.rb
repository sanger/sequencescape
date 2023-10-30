# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of a well
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class UpstreamWellResource < BaseResource
      model_name 'Well'
    end
  end
end
