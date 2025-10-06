# frozen_string_literal: true

##
# Api::Messages::CommentIo is responsible for serializing and exposing
# comment-related metadata linked to PolyMetadatum records. It maps domain
# attributes (such as batch, position, and tag index) into JSON for API
# consumption.
# PolyMetadatum object is expected to be of metadatable_type 'Request',
# and the request is expected to be assoicated to a batch.
# The included PolyMetadatumBatchAliquots module provides helper methods
# for traversing from PolyMetadatum → Batch → BatchRequest → Aliquots,
# filtering aliquots by those associated with the given PolyMetadatum.
#
class Api::Messages::CommentIo < Api::Base
  renders_model(::PolyMetadatum)

  module PolyMetadatumBatchAliquots
    ##
    # Collects all sample IDs from aliquots associated with the PolyMetadatum's
    # target asset.
    #
    # @return [Array<Integer>] sample IDs for this PolyMetadatum
    def sample_ids_with_poly_metadata
      metadatable.target_asset.aliquots.flat_map(&:sample_id)
    end

    ##
    # Collects all aliquot entries across related batches.
    #
    # @return [Array<Hash>] a list of hashes, each containing batch_id, position, and tag_index.
    def batch_aliquots
      related_batches.flat_map { |batch| aliquots_for_batch(batch) }
    end

    ##
    # Collects aliquots belonging to a single batch.
    #
    # @param batch [Batch] the batch object
    # @return [Array<Hash>] built entries for each matching aliquot
    def aliquots_for_batch(batch)
      batch.batch_requests.flat_map { |br| aliquots_for_batch_request(batch, br) }
    end

    ##
    # Collects aliquots belonging to a single batch request and builds entries.
    #
    # @param batch [Batch]
    # @param batch_request [BatchRequest]
    # @return [Array<Hash>] entries for matching aliquots
    def aliquots_for_batch_request(batch, batch_request)
      matching_aliquots(batch_request).map do |aliquot|
        build_entry(batch, batch_request, aliquot)
      end
    end

    ##
    # Selects aliquots from a batch request that match this PolyMetadatum's
    # sample IDs.
    #
    # @param batch_request [BatchRequest]
    # @return [Array<Aliquot>] aliquots with matching sample IDs
    def matching_aliquots(batch_request)
      batch_request.request.asset.aliquots.select do |a|
        sample_ids_with_poly_metadata.include?(a.sample_id)
      end
    end

    # Builds a hash entry for a given aliquot, including batch, request position,
    # and aliquot index value.
    #
    # @param batch [Batch]
    # @param batch_request [BatchRequest]
    # @param aliquot [Aliquot]
    # @return [Hash] entry with :batch_id, :position, and :tag_index
    def build_entry(batch, batch_request, aliquot)
      {
        batch_id: batch.id,
        position: batch_request.position,
        tag_index: aliquot.aliquot_index_value
      }
    end

    def current_entry
      # Return the first entry, as only one aliquot is expected
      # for the PolyMetadatum of Request type.
      @current_entry ||= batch_aliquots.first || {}
    end

    def batch_id
      current_entry[:batch_id]
    end

    def position
      current_entry[:position]
    end

    def tag_index
      current_entry[:tag_index]
    end
  end
  map_attribute_to_json_attribute(:key, 'comment_type')
  map_attribute_to_json_attribute(:value, 'comment_value')
  map_attribute_to_json_attribute(:updated_at, 'last_updated')
  map_attribute_to_json_attribute(:batch_id, 'batch_id')
  map_attribute_to_json_attribute(:position, 'position')
  map_attribute_to_json_attribute(:tag_index, 'tag_index')
end
