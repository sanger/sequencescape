# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {PlateTemplate}.
    #
    # Plate templates are virtual plates used to define pre-assigned layouts or
    # blank well patterns for downstream workflows.
    class PlateTemplateResource < BaseResource
      immutable

      default_includes :uuid_object

      attribute :uuid, readonly: true
      attribute :name, readonly: true

      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(*value) }
    end
  end
end
