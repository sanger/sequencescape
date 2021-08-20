# Handles the behaviour of {AddSpikedInControlTask} and included in {WorkflowsController}
# {include:AddSpikedInControlTask}
module Tasks::AddSpikedInControlHandler
  # rubocop:todo Metrics/MethodLength
  def do_add_spiked_in_control_task(task, params) # rubocop:todo Metrics/AbcSize
    batch = @batch || Batch.find(params[:batch_id])
    barcode = params[:barcode].first
    control = SpikedBuffer.find_by_barcode(barcode)
    request_id_set = Set.new
    params[:request].each { |k, v| request_id_set << k.to_i if v == 'on' }

    unless control
      flash[:error] = "Can't find a spiked hybridization buffer with barcode #{barcode}"
      return false
    end

    Batch.transaction do
      task.add_control(batch, control, request_id_set)
      create_batch_events(batch, task)
    end
  end
  # rubocop:enable Metrics/MethodLength
end
