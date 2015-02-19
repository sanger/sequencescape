#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
module Tasks::StartBatchHandler

  def do_start_batch_task(task, params)
    return unless task.lab_activity?
    Batch.find(params[:batch_id]).start!(current_user) unless @batch.started? or @batch.failed?
  end

end
