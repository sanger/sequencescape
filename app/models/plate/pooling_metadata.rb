# frozen_string_literal: true

module Plate::PoolingMetadata
  # TODO: When API v1 is removed, this could stop returning the pool_id as v2 is only using the location arrays.
  #   When that happens, the v2 Resource would need to stop extracting those arrays from this hash.
  #
  # Returns a hash, keyed by submission UUID, describing the pools formed by the wells on this plate.
  # Each value contains: { wells:, pool_complete:, request_type:, for_multiplexing:, insert_size:,
  # library_type:, pcr_cycles: ... } — the latter keys are injected polymorphically by
  # Request#update_pool_information (and its subclass overrides).
  #
  # Unpooled wells (those without a submission) are excluded.
  #
  # Performance notes:
  # * `for_pooling_of` uses a custom SELECT/GROUP BY which silently disables `includes` eager loading
  #   (https://github.com/rails/rails/issues/15185), so we use `preload` to actually eager-load the
  #   `request_metadata` and `request_type` associations that every `update_pool_information` call reads.
  # * Short-circuit when the plate has no submissions to avoid running the grouped query at all.
  # * Memoised because the JSON:API serializer may read this attribute more than once per render.
  def pools
    @pools ||= build_pools
  end

  private

  def build_pools
    return {} if all_submission_ids.blank?

    Request
      .for_pooling_of(self)
      .preload(:request_metadata, :request_type)
      .each_with_object({}) do |request, pools|
        next if request.pool_id.nil?

        pool_information = { wells: request.pool_into.split(','), pool_complete: request.pool_complete == 1 }
        request.update_pool_information(pool_information)
        pools[request.pool_id] = pool_information
      end
  end
end
