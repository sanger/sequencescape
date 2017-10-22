# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2014,2015 Genome Research Ltd.

module Tasks::SamplePrepQcHandler
  def render_sample_prep_qc_task(task, params)
    @requests = task.find_batch_requests(params[:batch_id])
  end

  def do_sample_prep_qc_task(task, params)
    requests = task.find_batch_requests(params[:batch_id])

    params[:request].each do |request_id, qc_status|
      requests_found = requests.select { |request| request.id == request_id.to_i }
      request = requests_found.first
      if request.nil?
        flash[:error] = "Couldnt find Request #{request_id}"
        return false
      end
      if qc_status == 'failed'
        request.fail!
      elsif qc_status == 'passed'
        request.pass!
        request.target_asset.pac_bio_library_tube_metadata.update_attributes!(smrt_cells_available: 1)
      else
        flash[:error] = "Invalid QC state for #{request_id}"
        return false
      end
    end

    true
  end
end
