class MultiplexedSubmission < LinearSubmission
  # Overrides the standard behaviour so that the target asset of the initial request type requests is the same,
  # and that it is also the source asset of the final sequencing request.  It's assumed to be a multiplexed
  # library tube as this is only here to support the pulldown pipelines at the moment.
  def process_submission!
    super
    attach_multiplexed_library_tube
  end

  def attach_multiplexed_library_tube
    identify_pool_related_requests do |requests_into_pool, request_from_pool|
      tube = MultiplexedLibraryTube.create! do |tube|
        tube.barcode = AssetBarcode.new_barcode
      end
      requests_into_pool.each { |request| request.update_attributes!(:target_asset => tube) }
      request_from_pool.update_attributes!(:asset => tube)
    end
  end
  private :attach_multiplexed_library_tube

  def identify_pool_related_requests(&block)
    # Find the request type that does the pooling first.  The one that immediate follows it will be the
    # one that comes out of that pool.
    #
    # TODO: By 'follows' I mean 'preceeds' as it's all backwards here!
    pooling_request_type, index = nil, -1
    request_types.each_with_index do |request_type_id, i|
      request_type = RequestType.find(request_type_id)
      next unless request_type.for_multiplexing?

      pooling_request_type, index = request_type, i
      break
    end
    raise StandardError, "There seem to be no pooling request types" if pooling_request_type.nil?
    out_of_pool_request_type = RequestType.find(request_types[index-1])

    # Now sort the requests into their appropriate groups so that we can do the right thing.
    requests_into_pool, request_from_pool = [], nil
    requests.each do |request|
      if request.request_type == pooling_request_type
        requests_into_pool << request
      elsif request.request_type == out_of_pool_request_type
        raise StandardError, "Cannot handle multiple requests out of pools" if request_from_pool.present?
        request_from_pool = request
      end
    end

    raise StandardError, "There appear to be no pooling requests"      if requests_into_pool.empty?
    raise StandardError, "There is no request leading out of the pool" if request_from_pool.nil?
    yield(requests_into_pool, request_from_pool)
  end
  private :identify_pool_related_requests
end
