module Tasks::DnaQcHandler
  def render_dna_qc_task(task, params)
    @batch = Batch.find(params[:batch_id], :include => [{ :requests => :request_metadata }, :pipeline, :lab_events])
    @rits = @batch.pipeline.request_information_types
    @requests = @batch.requests.all(
      :include => {
        :source_well => [
          :external_properties,
          :map,
          :plate,
          :well_attribute,
          { :aliquots => [ :tag, { :sample => :sample_metadata } ] }
        ]
      },
      :order => 'maps.column_order ASC'
    )

    unless @batch.started? || @batch.failed?
      @batch.start!(current_user)
    end

    @workflow = LabInterface::Workflow.find(params[:workflow_id], :include => [:tasks])
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
