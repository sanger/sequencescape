# frozen_string_literal: true
module Tasks::StartBatchHandler # rubocop:todo Style/Documentation
  def do_start_batch_task(task, params)
    return unless task.lab_activity?

    Batch.find(params[:batch_id]).start!(current_user) if @batch.may_start?
  end
end
