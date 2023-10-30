# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of submission
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class DirectSubmissionResource < BaseResource
      model_name 'Submission'
    end
  end
end
