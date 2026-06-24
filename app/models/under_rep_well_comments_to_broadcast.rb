# frozen_string_literal: true

# This module encapsulates the logic for identifying and generating comment
# data related to "under-represented" wells within a released batch.
# under_represented poly_metadata entries are linked to library requests associated with wells containing
# under-represented samples.
#
# It supports:
#   - Pipelines where all requests (library prep, multiplexing, sequencing)
#     belong to a single submission (e.g. WGS)
#   - Pipelines where sequencing and library prep requests belong to
#     different submissions (e.g. RNA)
#   - Pipelines where the plate marked with “under-represented” wells is at the bottom of the request chain
#   - TODO: `Pipelines where the plate marked with “under-represented”
#     TODO: wells is in the middle of the request chain (e.g ISC ) Y26-167`
#
# Responsibilities:
#   - Retrieve ancestor plates from batch lanes
#   - Extract requests containing `under_represented` metadata from the
#     ancestor plates
#   - Build structured `UnderRepWellComment` objects representing
#     per-well comments for serialization or broadcasting
#   - Handle `under_represented` poly_metadata linked to library requests
#     and attached to wells containing under-represented samples
#   - Provide a `comments` method used by `CommentIO` for serialization

module UnderRepWellCommentsToBroadcast
  UNDER_REPRESENTED_KEY = 'under_represented'

  # Represents a single "under-represented" well comment, holding metadata
  # about its batch, position, tag index, and associated poly_metadatum.

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

  # Entry point used by CommentIO to retrieve the comments to serialize.
  #
  # @return [Array<UnderRepWellComment>] comments representing under-represented wells.
  def under_rep_comments
    under_represented_well_comments || []
  end

  ##
  # Builds all `UnderRepWellComment` objects for the batch by iterating over
  # each sequencing request and its associated lane.
  # Aggregates comments across  all lanes and their ancestor plates.
  # @return [Array<UnderRepWellComment>] a flat list of comment objects.
  def under_represented_well_comments
    requests.flat_map do |sequencing_request|
      lane = sequencing_request.target_asset
      uniq_comments_for_lane(lane, sequencing_request) unless lane.nil?
    end
  end

  private

  # Remove duplicates to handle cases where a pool is created from two PCR XP plates derived from each other,
  # and where the same well positions are marked as under-represented in both plates.
  # (Example: Triomics pipeline LCMT DNA PCR XP and LCMT EM PCR XP plates)
  # These do not need to be tracked separately, as the wells in different plates refer to the same samples.
  # @param lane [Lane] the lane receptacle associated with the batch request
  # @param sequencing_request [Request] the sequencing request whose position is used in the comment
  # @return [Array<UnderRepWellComment>] comments built for the given lane
  def uniq_comments_for_lane(lane, sequencing_request)
    build_comments_for_lane(lane, sequencing_request).uniq do |comment|
      [comment.batch_id, comment.position, comment.tag_index,
       comment.poly_metadatum.key, comment.poly_metadatum.value]
    end
  end

  # Coordinates comment building for a single lane by finding all under-represented
  # library requests in the lane's ancestor plates, then building a comment for
  # each associated poly_metadatum.
  # @param lane [Lane] the lane receptacle associated with the batch request
  # @param sequencing_request [Request] the sequencing request whose position is used in the comment
  # @return [Array<UnderRepWellComment>] comments built for the given lane
  def build_comments_for_lane(lane, sequencing_request)
    under_rep_requests_for_lane(lane).flat_map do |library_request|
      under_represented_poly_metadata(library_request).flat_map do |poly_meta|
        build_comments(library_request, lane, sequencing_request, poly_meta)
      end
    end
  end

  # Traverses the ancestor plates of a lane to find all library requests
  # containing an `under_represented` poly_metadata entry. Covers both
  # single-submission pipelines (e.g. WGS) and multi-submission pipelines
  # (e.g. RNA) where sequencing and library prep belong to different submissions.
  #
  # @param lane [Lane] the lane whose ancestor plates are traversed
  # @return [Array<Request>] requests containing under-represented metadata
  def under_rep_requests_for_lane(lane)
    lane.ancestors.grep(Plate)
      .flat_map(&:wells)
      .flat_map(&:requests).compact.uniq
      .select { |r| r.poly_metadata.any? { |pol| pol.key == UNDER_REPRESENTED_KEY } }
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
  # Constructs `UnderRepWellComment` objects for a single request,
  # filtering only poly_metadata that correspond to under-represented wells.
  # Iterates over the well's aliquots and matches each against the lane aliquots to retrieve the correct
  # tag index and position.
  #
  # @param library_request [Request] the library request whose target_asset well holds the aliquots
  # @param lane [Lane] the lane asset used to find matching aliquots and retrieve the tag index
  # @param sequencing_request [Request] the sequencing request providing the lane position
  # @param poly_meta [PolyMetadatum] the under-represented metadata record to associate with the comment
  # @return [Array<UnderRepWellComment>] comments built for each matching aliquot
  def build_comments(library_request, lane, sequencing_request, poly_meta)
    library_request.target_asset.aliquots.filter_map do |aliquot|
      matching = find_matching_lane_aliquot(lane, aliquot)
      next unless matching

      UnderRepWellComment.new(
        position: sequencing_request.batch_request.position,
        batch_id: id,
        tag_index: matching.aliquot_index_value,
        poly_metadatum: poly_meta
      )
    end
  end

  ##
  # Determines whether the given aliquot matches an aliquot on the lane
  # A match requires equality on:
  #   - `sample_id`
  #   - `tag_id`
  #   - `tag2_id`
  #   - `tag_depth`
  #
  # This comparison is used to associate aliquots that were marked as 'under-represented' with their
  # downstream lane aliquots in order to retrieve the correct tag index for the comment.
  #
  # @param lane [Asset] the lane asset derived from the request
  # @param aliquot [Aliquot] the aliquot being compared
  # @return [Aliquot, nil] the matching lane aliquot, or nil if no match is found
  def find_matching_lane_aliquot(lane, aliquot)
    lane.aliquots.find do |a|
      aliquot.equivalent?(a, %w[sample_id tag_id tag2_id tag_depth])
    end
  end
end
