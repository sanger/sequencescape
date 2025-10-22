# frozen_string_literal: true

# This module encapsulates logic for identifying and generating comment data
# related to "under-represented" wells within a released batch.
#
# It:
#   - Extracts requests containing "under_represented" metadata.
#   - Builds structured `UnderRepWellComment` objects that represent
#     per-well comments to be serialized or broadcasted.
#   - Provides a `comments` method used by CommentIO for serialization.
#
module UnderRepWellCommentsToBroadcast
  UNDER_REPRESENTED_KEY = 'under_represented'

  # Represents a single "under-represented" well comment, holding metadata
  # about its batch, position, tag index, and associated poly_metadatum.
  #
  # @attr_reader [Object] poly_metadatum The metadata object describing the comment.
  # @attr_reader [Integer] batch_id The ID of the batch this comment belongs to.
  # @attr_reader [Integer] position The lane or well position of the comment.
  # @attr_reader [Integer] tag_index The tag index identifying the aliquot.
  class UnderRepWellComment
    attr_reader :poly_metadatum, :position, :tag_index, :batch_id

    def initialize(poly_metadatum:, batch_id:, position:, tag_index:)
      @poly_metadatum = poly_metadatum
      @batch_id = batch_id
      @position = position
      @tag_index = tag_index
    end

    delegate :key, to: :poly_metadatum
    delegate :value, to: :poly_metadatum
    delegate :updated_at, to: :poly_metadatum
    delegate :deleted_at, to: :poly_metadatum
    delegate :destroyed?, to: :poly_metadatum
  end

  # Returns all requests related to the batch that include a poly_metadatum entry
  # with the `UNDER_REPRESENTED` key.
  #
  # @return [Array<Request>] an array of requests that contain under-represented metadata.
  def request_with_under_represented_wells
    submissions.flat_map(&:requests).select do |r|
      r.poly_metadata.any? { |pol| pol.key == UNDER_REPRESENTED_KEY }
    end
  end

  ##
  # Builds all `UnderRepWellComment` objects for requests within the batch
  # that have under-represented wells. The resulting list aggregates comments
  # across multiple requests and associated assets.
  #
  # @return [Array<UnderRepWellComment>] a flat list of comment objects.
  #
  def under_represented_well_comments
    request_with_under_represented_wells.flat_map do |request|
      build_comments_for_request(request)
    end.compact
  end

  # Entry point used by CommentIO to retrieve the comments to serialize.
  #
  # @return [Array<UnderRepWellComment>] comments representing under-represented wells.
  def comments
    under_represented_well_comments || []
  end

  private

  ##
  # Constructs `UnderRepWellComment` objects for a single request,
  # filtering only poly_metadata that correspond to under-represented wells.
  #
  # @param request [Request] the request to process
  # @return [Array<UnderRepWellComment>] comments built for the given request
  #
  def build_comments_for_request(request)
    under_represented_poly_metadata(request).flat_map do |poly_meta|
      build_comments_for_poly_meta(request, poly_meta)
    end
  end

  ##
  # Returns only those `PolyMetadatum` records whose key matches
  # the `UNDER_REPRESENTED_KEY` constant.
  #
  # @param request [Request] the request whose poly_metadata to inspect
  # @return [Array<PolyMetadatum>] filtered poly_metadata records
  #
  def under_represented_poly_metadata(request)
    request.poly_metadata.select { |meta| meta.key == UNDER_REPRESENTED_KEY }
  end

  ##
  # Builds comments for a specific poly_metadatum by iterating through
  # all target aliquots and matching them to lane aliquots by tag map ID.
  #
  # The starting point is the request that holds the poly_metadatum for the
  # under-represented well. This request is typically a LibraryRequest, whose
  # asset corresponds to the under-represented well.
  #
  # From there, we traverse to the Lane asset via `request.asset.descendants`.
  # The Lane provides access to the `batch_request` (through `lane.source_request`),
  # which contains the lane position information used in the generated comment.
  #
  # @param request [Request] the request that owns the poly_metadatum
  # @param poly_meta [PolyMetadatum] the metadata record for under-represented wells
  # @return [Array<UnderRepWellComment>] list of constructed comment objects

  def build_comments_for_poly_meta(request, poly_meta)
    request.target_asset.aliquots.filter_map do |aliquot|
      lane = request.asset.descendants.last
      next unless aliquot_matches_lane?(lane, aliquot)

      UnderRepWellComment.new(
        position: lane.source_request.position,
        batch_id: id,
        tag_index: aliquot.tag.map_id,
        poly_metadatum: poly_meta
      )
    end
  end

  ##
  # Checks if the given aliquot’s tag map ID matches any aliquot in the lane.
  #
  # @param lane [Asset] the lane asset derived from the request
  # @param aliquot [Aliquot] the aliquot being compared
  # @return [Boolean] true if the aliquot matches a lane aliquot by index value
  #
  def aliquot_matches_lane?(lane, aliquot)
    lane.aliquots.any? { |a| a.aliquot_index_value == aliquot.tag.map_id }
  end
end
