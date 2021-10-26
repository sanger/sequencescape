# frozen_string_literal: true

module Api
  module V2
    # SampleManifestResource
    class SampleManifestResource < BaseResource
      immutable # comment to make the resource mutable

      default_includes :uuid_object

      attribute :supplier_name
    end
  end
end
