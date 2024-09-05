# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API controller for barcode printers.
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation.
    class BarcodePrintersController < JSONAPI::ResourceController
      # By default JSONAPI::ResourceController provides most of the standard
      # behaviour, and in many cases this file may be left empty.
    end
  end
end
