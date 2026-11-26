# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Tag2LayoutTemplate}.
    class Tag2LayoutTemplateResource < BaseResource
      immutable

      default_includes :uuid_object

      attribute :uuid, readonly: true
      attribute :name, readonly: true

      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(*value) }
    end
  end
end
