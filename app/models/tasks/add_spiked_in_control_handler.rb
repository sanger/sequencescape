# frozen_string_literal: true
# Handles the behaviour of {AddSpikedInControlTask} and included in {WorkflowsController}
# {include:AddSpikedInControlTask}
module Tasks::AddSpikedInControlHandler
  # The handler takes the parameters for the task and
  # helps add the scanned Spiked PhiX as a parent of each lane
  class Handler < Tasks::BaseHandler
    def perform
      # Rubocop gets in a fight with prettier here.
      if missing_barcodes.present?
        return false, "Can't find a spiked hybridization buffer with barcode #{missing_barcodes.to_sentence}"
      end

      Batch.transaction { add_control ? create_batch_events : false }
    end

    private

    def phi_x_per_request
      @phi_x_per_request ||=
        params[:barcode].transform_values do |barcode|
          next if barcode.blank?

          phi_x_buffers.detect { |tube| tube.any_barcode_matching?(barcode) }
        end
    end

    def missing_barcodes
      @missing_barcodes ||=
        params[:barcode].values.reject do |barcode|
          barcode.empty? || phi_x_buffers.detect { |tube| tube.any_barcode_matching?(barcode) }
        end
    end

    def phi_x_buffers
      @phi_x_buffers ||= SpikedBuffer.with_barcode(params[:barcode].values)
    end

    def add_control
      requests.each do |request|
        next unless selected_requests.include?(request.id) && request.lane

        process_request(request)
      end

      # We touch the batch to ensure any flowcell messages have an updated timestamp
      batch.touch # rubocop:disable Rails/SkipsModelValidations
      batch.requests.all? { |r| r.has_passed(batch, task) }
    end

    def process_request(request)
      lane = request.lane
      phi_x_tube = phi_x_per_request[request.id.to_s] || phi_x_per_request[:all]
      lane.direct_spiked_in_buffer = nil
      lane.direct_spiked_in_buffer = phi_x_tube if phi_x_tube
      LabEvent.create!(
        batch: batch,
        description: task.name,
        descriptors: descriptors_for(phi_x_tube),
        user: user,
        eventful: request
      )
    end

    def descriptors_for(phi_x_tube)
      if phi_x_tube
        {
          'PhiX added' => true,
          'Scanned PhiX' => phi_x_tube.human_barcode,
          'PhiX Stock Barcode' => phi_x_tube.parent&.human_barcode
        }
      else
        { 'PhiX added' => false }
      end
    end

    def batch
      @batch ||= Batch.find(params[:batch_id])
    end
  end
end
