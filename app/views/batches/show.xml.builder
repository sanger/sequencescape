xml.instruct!
xml.batch {
  xml.id     @batch.id
  xml.status @batch.state
  xml.lanes {
    @batch.ordered_requests.each do |request|
      xml.lane("position" => request.position(@batch)) {
        # This batch seems very broken!
        if request.asset.nil?
          xml.comment!("The request #{request.id} has no source asset which is very bad!")
          next
        end

        # Requests that have a source control asset do not have target assets, so we output them 
        # seperately and loop around.
        if request.asset.resource?
          xml.control(
            "id"         => request.asset.id,
            "name"       => request.asset.name,
            "request_id" => request.id
          ) {
            request.asset.aliquots.each { |aliquot| output_aliquot(xml, aliquot) }
          }
          next    # Loop as there will never be a spiked in buffer on this.
        end

        # If there are no aliquots in the target asset and the batch is not pending then we likely have
        # an error.  If the batch is pending then the aliquots are assumed to have not been transferred
        # so the lane is effectively empty.
        raise StandardError, "Empty lane #{request.target_asset.id} in batch #{@batch.id}" if not @batch.pending? and request.target_asset.aliquots.empty?

        if request.target_asset.aliquots.empty?
          # This is a batch that has yet to be started
          xml.comment!("This batch has yet to be started so no information about what's on this lane is available yet")
        elsif request.target_asset.aliquots.map(&:tag).compact.empty?
          # This is a lane that is not multiplexed
          xml.library(
            "id"         => request.target_asset.primary_aliquot.library_id,  # TODO: remove
            "sample_id"  => request.target_asset.primary_aliquot.sample_id,   # TODO: remove
            "name"       => request.asset.name,                               # TODO: remove
            "request_id" => request.id,
            "study_id"   => request.target_asset.primary_aliquot.study_id,    # TODO: remove
            "project_id" => request.target_asset.primary_aliquot.project_id,  # TODO: remove
            "qc_state"   => request.target_asset.compatible_qc_state
          ) {
            request.target_asset.aliquots.each { |aliquot| output_aliquot(xml, aliquot) }
          }
        else
          # Anything else is assumed to be a multiplexed lane
          xml.pool(
            "id"         => request.asset.id,                                 # TODO: remove
            "name"       => request.asset.name,                               # TODO: remove
            "request_id" => request.id,
            "study_id"   => request.target_asset.primary_aliquot.study_id,    # TODO: remove
            "project_id" => request.target_asset.primary_aliquot.project_id,  # TODO: remove
            "qc_state"   => request.target_asset.compatible_qc_state
          ) {
            request.target_asset.aliquots.each { |aliquot| output_aliquot(xml, aliquot) }
          }
        end

        # Deal with spiked in buffers
        if (hybridisation_buffer = request.target_asset.spiked_in_buffer).present?
          index, aliquot = hybridisation_buffer.index, hybridisation_buffer.primary_aliquot

          xml.hyb_buffer("id" => hybridisation_buffer.id) {
            xml.control("id" => index.id, "name" => index.name) if index.present?
            output_aliquot(xml, aliquot)
          }
        end
      }
    end
  }
}
