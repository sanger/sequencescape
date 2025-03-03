# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note Access this resource via the `/api/v2/aliquots/` endpoint.
    #
    # Provides a JSON:API representation of {Aliquot}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class AliquotResource < BaseResource
      # Associations
      has_one :study
      has_one :project
      has_one :sample
      has_one :request
      has_one :receptacle
      has_one :tag
      has_one :tag2
      has_one :library

      # Attributes
      attribute :tag_oligo, write_once: true
      attribute :tag_index, write_once: true
      attribute :tag2_oligo, write_once: true
      attribute :tag2_index, write_once: true
      attribute :suboptimal, write_once: true
      attribute :library_type, write_once: true
      attribute :insert_size_to, write_once: true

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
