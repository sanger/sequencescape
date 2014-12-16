class IlluminaHtp::PooledPlatePurpose < PlatePurpose
  def transition_to(plate, state, contents = nil, customer_accepts_responsibility = false)
    ActiveRecord::Base.transaction do
      super
      if (state=='passed')
        plate.parent.wells.each do |well|
          library_creation_request = well.creation_request
          requests = library_creation_request.submission.obtain_next_requests_to_connect(library_creation_request)
          requests.each {|r| r.update_attributes!(:asset => well) }
        end
      end
    end
  end

end
