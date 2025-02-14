# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Aliquot}, which represents a specific portion of material
    # within a liquid. This material could be the DNA of a sample, or it might be a library (a combination of the DNA
    # sample and a {Tag tag}).
    #
    # @note Access this resource via the `/api/v2/aliquots/` endpoint.
    #
    # @example POST request to create an aliquot with associated relationships
    #   POST /api/v2/aliquots/
    #   {
    #     "data": {
    #       "type": "aliquots",
    #       "attributes": {
    #         "suboptimal": false,
    #         "library_type": "RNA",
    #         "insert_size_to": 400
    #       },
    #       "relationships": {
    #         "study": { "data": { "type": "studies", "id": "123" } },
    #         "project": { "data": { "type": "projects", "id": "456" } },
    #         "sample": { "data": { "type": "samples", "id": "789" } },
    #         "request": { "data": { "type": "requests", "id": "321" } },
    #         "receptacle": { "data": { "type": "receptacles", "id": "654" } },
    #         "tag": { "data": { "type": "tags", "id": "987" } },
    #         "tag2": { "data": { "type": "tags", "id": "876" } },
    #         "library": { "data": { "type": "libraries", "id": "555" } }
    #       }
    #     }
    #   }
    #
    # @example GET request for all Aliquot resources
    #   GET /api/v2/aliquots/
    #
    # @example GET request for a specific Aliquot by ID
    #   GET /api/v2/aliquots/123/
    #
    # @example Filtering by project ID
    #   GET /api/v2/aliquots/?filter[project]=456
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or the [JSONAPI::Resources](http://jsonapi-resources.com/) package, which implements JSON:API for Sequencescape.
    class AliquotResource < BaseResource
      default_includes :tag, :tag2

      ###
      # Attributes
      ###

      # @!attribute [r] tag_oligo
      #   @deprecated Use {#tag} instead. The tag should already exist.
      #   @return [String, nil] The oligo sequence of the primary tag.
      #   @note This attribute is read-only; the `write_once` functionality is unimplemented.
      attribute :tag_oligo, write_once: true

      # @!attribute [r] tag_index
      #   @deprecated Use {#tag} instead. The tag should already exist.
      #   @return [Integer, nil] The index position of the primary tag.
      #   @note This attribute is read-only; the `write_once` functionality is unimplemented.
      attribute :tag_index, write_once: true

      # @!attribute [r] tag2_oligo
      #   @deprecated Use {#tag2} instead. The tag should already exist.
      #   @return [String, nil] The oligo sequence of the secondary tag.
      #   @note This attribute is read-only; the `write_once` functionality is unimplemented.
      attribute :tag2_oligo, write_once: true

      # @!attribute [r] tag2_index
      #   @deprecated Use {#tag2} instead. The tag should already exist.
      #   @return [Integer, nil] The index position of the secondary tag.
      #   @note This attribute is read-only; the `write_once` functionality is unimplemented.
      attribute :tag2_index, write_once: true

      # @!attribute [rw] suboptimal
      #   @return [Boolean] Indicates whether this aliquot is considered suboptimal.
      attribute :suboptimal, write_once: true

      # @!attribute [rw] library_type
      #   @return [String] The type of library associated with this aliquot.
      attribute :library_type, write_once: true

      # @!attribute [w] insert_size_to
      #   @return [Integer, nil] The upper bound of the insert size range for sequencing.
      attribute :insert_size_to, write_once: true

      ###
      # Relationships
      ###

      # @!attribute [rw] study
      #   @return [StudyResource] The study associated with this aliquot.
      has_one :study

      # @!attribute [rw] project
      #   @return [ProjectResource] The project this aliquot belongs to.
      has_one :project

      # @!attribute [rw] sample
      #   @return [SampleResource] The sample that this aliquot represents.
      has_one :sample

      # @!attribute [rw] request
      #   @return [RequestResource] The request associated with this aliquot.
      has_one :request

      # @!attribute [rw] receptacle
      #   @return [ReceptacleResource] The receptacle (well or tube) containing this aliquot.
      has_one :receptacle

      # @!attribute [rw] tag
      #   @return [TagResource] The primary tag associated with this aliquot.
      has_one :tag

      # @!attribute [rw] tag2
      #   @return [TagResource] The secondary tag associated with this aliquot.
      has_one :tag2

      # @!attribute [rw] library
      #   @return [LibraryResource] The library associated with this aliquot.
      has_one :library

      ###
      # Filters
      ###

      # Allows filtering by project ID.
      # @example
      #   GET /api/v2/aliquots/?filter[project]=456
      filter :project

      ###
      # Custom Methods
      ###

      # Retrieves the oligo sequence of the primary tag.
      # @deprecated Use {#tag} instead.
      # @return [String, nil] The oligo sequence of the primary tag, if available.
      # @note This attribute is read-only; the `write_once` functionality is unimplemented.
      def tag_oligo
        _model.tag&.oligo
      end

      # Retrieves the index of the primary tag.
      # @deprecated Use {#tag} instead.
      # @return [Integer, nil] The index of the primary tag, if available.
      # @note This attribute is read-only; the `write_once` functionality is unimplemented.
      def tag_index
        _model.tag&.map_id
      end

      # Retrieves the oligo sequence of the secondary tag.
      # @deprecated Use {#tag2} instead.
      # @return [String, nil] The oligo sequence of the secondary tag, if available.
      # @note This attribute is read-only; the `write_once` functionality is unimplemented.
      def tag2_oligo
        _model.tag2&.oligo
      end

      # Retrieves the index of the secondary tag.
      # @deprecated Use {#tag2} instead.
      # @return [Integer, nil] The index of the secondary tag, if available.
      # @note This attribute is read-only; the `write_once` functionality is unimplemented.
      def tag2_index
        _model.tag2&.map_id
      end
    end
  end
end
