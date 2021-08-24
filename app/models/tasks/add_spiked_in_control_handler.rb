# Handles the behaviour of {AddSpikedInControlTask} and included in {WorkflowsController}
# {include:AddSpikedInControlTask}
module Tasks::AddSpikedInControlHandler
  # rubocop:todo Metrics/MethodLength
  # rubocop:todo Metrics/CyclomaticComplexity
  # rubocop:todo Metrics/AbcSize
  # rubocop:todo Metrics/PerceivedComplexity
  def do_add_spiked_in_control_task(task, params)
    batch = @batch || Batch.find(params[:batch_id])
    phi_x_buffers = SpikedBuffer.with_barcode(params[:barcode].values)
    phi_x_per_request =
      params[:barcode].transform_values do |barcode|
        next if barcode.blank?
        phi_x_buffers.detect { |tube| tube.any_barcode_matching?(barcode) } ||
          (
            flash[:error] = "Can't find a spiked hybridization buffer with barcode #{barcode}"
            return false
          )
      end
    request_id_set = params[:request].keys.map(&:to_i)

    # phi_x_per_request.each do |barcode, tube|
    #   next unless barcode.present? && tube.nil?
    #   flash[:error] = "Can't find a spiked hybridization buffer with barcode #{barcode}"
    #   return false
    # end

    Batch.transaction do
      if task.add_control(batch, phi_x_per_request, request_id_set, current_user)
        create_batch_events(batch, task)
      else
        false
      end
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/PerceivedComplexity
end
