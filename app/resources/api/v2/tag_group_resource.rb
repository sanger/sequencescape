# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of TagGroup
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class TagGroupResource < BaseResource
      # Constants...

      # immutable # uncomment to make the resource immutable

      # model_name / model_hint if required

      default_includes :uuid_object, :tags

      # Associations:
      has_one :tag_group_adapter_type, foreign_key: :adapter_type_id, readonly: true, class_name: 'TagGroupAdapterType', relation_name: :adapter_type

      # Attributes
      attribute :uuid, readonly: true
      attribute :name, readonly: true
      attribute :tags, readonly: true

      # Filters
      filter :visible, default: true
      filter :name
      filter :tag_group_adapter_type_name, apply: ->(records, value, _options) { records.by_adapter_type(value) }

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # Class method overrides
      # We inline tags to better isolate our implementation
      def tags
        _model.tags.sort_by(&:map_id).map { |tag| { index: tag.map_id, oligo: tag.oligo } }
      end
    end
  end
end
