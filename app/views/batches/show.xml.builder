# frozen_string_literal: true
xml.instruct!
xml.batch do
  xml.id @batch.id
  xml.status @batch.state

  if @batch.sequencing?
    xml.lanes do
      @batch
        .batch_requests
        .ordered
        .includes(
          request: [
            {
              target_asset: {
                labware: {
                  direct_spiked_in_buffer: [:index, { aliquots: %i[library tag tag2 aliquot_index sample] }],
                  most_recent_spiked_in_buffer: [:index, { aliquots: %i[library tag tag2 aliquot_index sample] }]
                },
                aliquots: %i[library tag tag2 aliquot_index bait_library sample]
              }
            },
            :asset,
            :submission
          ]
        )
        .each do |batch_request|
          request = batch_request.request
          xml.lane(
            'position' => batch_request.position,
            'id' => request.target_asset_id,
            'priority' => request.priority
          ) do
            # This batch seems very broken!
            if request.asset.nil?
              xml.comment!("The request #{request.id} has no source asset which is very bad!")
              next
            end

            # Requests that have a source control asset do not have target assets, so we output them
            # separately and loop around.
            if request.asset.resource?
              xml.control('id' => request.asset.id, 'name' => request.asset.library_name, 'request_id' => request.id) do
                request.asset.aliquots.each { |aliquot| output_aliquot(xml, aliquot) }
              end
              next # Loop as there will never be a spiked in buffer on this.
            end

            target_asset_aliquots = request.target_asset.aliquots

            # If there are no aliquots in the target asset and the batch is not pending then we likely have
            # an error.  If the batch is pending then the aliquots are assumed to have not been transferred
            # so the lane is effectively empty.
            if (not @batch.pending?) && target_asset_aliquots.empty?
              raise StandardError, "Empty lane #{request.target_asset.id} in batch #{@batch.id}"
            end

            if target_asset_aliquots.empty?
              # This is a batch that has yet to be started
              xml.comment!(
                "This batch has yet to be started so no information about what's on this lane is available yet"
              )
            elsif target_asset_aliquots.any?(&:tags?)
              # Any lane where every aliquot is tagged is considered to be a pool
              xml.pool(
                'id' => request.asset.id, # TODO: remove
                'name' => request.asset.library_name, # TODO: remove
                'request_id' => request.id,
                'qc_state' => request.target_asset.compatible_qc_state
              ) { target_asset_aliquots.each { |aliquot| output_aliquot(xml, aliquot) } }
            else
              # This is a lane that is not multiplexed.
              xml.library(
                'id' => request.target_asset.primary_aliquot.library_id, # TODO: remove
                'name' => request.asset.library_name, # TODO: remove
                'request_id' => request.id,
                'qc_state' => request.target_asset.compatible_qc_state
              ) { target_asset_aliquots.each { |aliquot| output_aliquot(xml, aliquot) } }
            end

            # Deal with spiked in buffers
            hybridisation_buffer = request.target_asset.spiked_in_buffer

            if hybridisation_buffer.present?
              index = hybridisation_buffer.index
              aliquot = hybridisation_buffer.primary_aliquot

              xml.hyb_buffer('id' => hybridisation_buffer.id) do
                xml.control('id' => index.id, 'name' => index.name) if index.present?
                output_aliquot(xml, aliquot)
              end
            end
          end
        end
    end
  else
    # XML generation assumes that it is operating on a sequencing request, and tags like 'lane' make
    # little sense in other contexts. We used to generate the xml regardless, which just resulted in
    # mistakes downstream. Here we return a helpful comment instead, allowing us to make some
    # performance optimizations in the code above, without worrying about generating 500s.
    xml.comment 'This is not a sequencing batch. Only sequencing batches have an xml representation.'
  end
end
