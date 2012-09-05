class SequencingPipeline < Pipeline
  def sequencing?
    true
  end

  # The guys in sequencing want to be able to re-run a request in another batch.  What we've agreed is that
  # the request will be failed and then an identical request will be resubmitted to their inbox.  The
  # "failed" request should not be charged for.
  def detach_request_from_batch(batch, request)
    request.fail!

    # Note that the request metadata also needs to be cloned for this to work.
    request.clone.tap do |request_clone|
      request_clone.update_attributes!(:state => 'pending', :target_asset_id => nil, :request_metadata => request.request_metadata.clone)
      request_clone.comments.create!(:description => "Automatically created clone of request #{request.id} which was removed from Batch #{batch.id} at #{DateTime.now()}")
      request.comments.create!(:description => "The request #{request_clone.id} is an automatically created clone of this one")
    end
  end
end
