# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of aliquot
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class AliquotResource < BaseResource
      # immutable # comment to make the resource mutable

      default_includes :tag, :tag2

      # Associations
      has_one :study
      has_one :project
      has_one :sample
      has_one :request, always_include_optional_linkage_data: true
      has_one :receptacle
      has_one :tag
      has_one :tag2, class_name: 'Tag'

      # Attributes
      attribute :tag_oligo, readonly: true
      attribute :tag_index, readonly: true
      attribute :tag2_oligo, readonly: true
      attribute :tag2_index, readonly: true
      attribute :suboptimal, readonly: true
      attribute :library_type, readonly: true

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      def tag_oligo
        _model.tag&.oligo
      end

      def tag_index
        _model.tag&.map_id
      end

      def tag2_oligo
        _model.tag2&.oligo
      end

      def tag2_index
        _model.tag2&.map_id
      end

      # Class method overrides
    end
  end
end
