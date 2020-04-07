# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of user
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class UserResource < BaseResource
      # Constants...

      immutable # comment to make the resource mutable

      # model_name / model_hint if required

      default_includes :uuid_object

      # Attributes
      attribute :uuid, readonly: true
      attribute :login, readonly: true
      attribute :first_name, readonly: true
      attribute :last_name, readonly: true

      # Filters
      filter :user_code, apply: lambda { |records, value, _options|
        records.with_user_code(*value)
      }
    end
  end
end
