class SequencingPipeline < Pipeline
  def sequencing?
    true
  end

  def request_actions
    [:remove]
  end

  def is_read_length_consistent_for_batch?(batch)
    
    if (batch.requests.size == 0) || (batch.requests.first.request_metadata.nil?)
      # No requests selected or the pipeline doesn't contain metadata to check       
      return true
    end
    
    read_length_list = batch.requests.map { |request|
      request.request_metadata.read_length
    }.compact
    
    # The pipeline doen't contain the read_length attribute
    return true if read_length_list.size == 0
    
    # There are some requests that don't have the read_length_attribute
    return false if read_length_list.size != batch.requests.size
    
    return (read_length_list.uniq.size == 1)
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
