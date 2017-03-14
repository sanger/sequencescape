# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2014,2015 Genome Research Ltd.

module Tasks::DnaQcHandler
  def render_dna_qc_task(task, params)
    @batch = Batch.includes({ requests: :request_metadata }, :pipeline, :lab_events).find(params[:batch_id])
    @batch.start!(current_user) if @batch.pending?
    @rits = @batch.pipeline.request_information_types

    @requests = @batch.requests.includes(
      source_well: [
        :external_properties,
        :map,
        :plate,
        :well_attribute,
        { aliquots: [:tag, { sample: :sample_metadata }] }
      # We sort in ruby as otherwise we end up wrestling with MySQL 5.7's requirement for the sort
      # to be in the select. We'll just end up wrestling with rails handling of the includes if
      # we try and force it here.
    ]).sort_by { |r| r.source_well.map.column_order }

    @workflow = LabInterface::Workflow.includes(:tasks).find(params[:workflow_id])
    @task = task # @workflow.tasks[params[:id].to_i]
    @stage = params[:id].to_i
    @count = 0

    @qc_results = @requests.map { |request| @task.create_render_element(request) }
  end

  def do_dna_qc_task(task, params)
    ActiveRecord::Base.transaction do
      params.each do |request_id, value|
        next unless request_id.to_i != 0
        request = Request.find request_id
        next unless request

        task.pass_request(request, @batch, value[:qc_state])
      end
    end

    true
  end
end
