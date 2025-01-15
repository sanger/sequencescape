# frozen_string_literal: true

module Plate::PoolingMetadata
  # TODO: When API v1 is removed, this could stop returning the pool_id as v2 is only using the location arrays.
  #   When that happens, the v2 Resource would need to stop extracting those arrays from this hash.
  # Returns a hash from the submission for the pools to the wells that form that pool on this plate.  This is
  # not necessarily efficient but it is correct.  Unpooled wells, those without submissions, are completely
  # ignored within the returned result.
  def pools
    Request
      .include_request_metadata
      .for_pooling_of(self)
      .each_with_object({}) do |request, pools|
        pools[request.pool_id] = {
          wells: request.pool_into.split(','),
          pool_complete: request.pool_complete == 1
        }.tap { |pool_information| request.update_pool_information(pool_information) } unless request.pool_id.nil?
      end
  end
end
