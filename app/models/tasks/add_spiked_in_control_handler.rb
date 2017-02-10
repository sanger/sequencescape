# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

module Tasks::AddSpikedInControlHandler
  def do_add_spiked_in_control_task(task, params)
    batch = @batch || Batch.find(params[:batch_id])
    barcode = params[:barcode].first
    control = SpikedBuffer.find_from_machine_barcode(barcode)
    request_id_set = Set.new
    params[:request].each do |k, v|
      request_id_set << k.to_i if v == 'on'
    end

    unless control
      flash[:error] = "Can't find a spiked hybridization buffer with barcode #{barcode}"
      return false
    end

    Batch.transaction do
      task.add_control(batch, control, request_id_set)
      eventify_batch(batch, task)
    end
  end
end
