# frozen_string_literal: true

module Api
  module V2
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class BioscanJobResource < BaseResource
      # Attributes
      attribute :barcode
    end
  end
end
