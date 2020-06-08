class SamplePrepQcTask < Task
  def partial
    'sample_prep_qc_batches'
  end

  def render_task(workflow, params)
    super
    workflow.render_sample_prep_qc_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_sample_prep_qc_task(self, params)
  end
end
