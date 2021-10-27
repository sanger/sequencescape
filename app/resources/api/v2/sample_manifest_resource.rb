# frozen_string_literal: true

module Api
  module V2
    # Class required by json-api-resources gem to support serving the information from
    # a sample manifest.
    class SampleManifestResource < BaseResource
      immutable # comment to make the resource mutable

      default_includes :uuid_object

      # Name of the supplier of the sample manifest
      attribute :supplier_name
    end
  end
end
