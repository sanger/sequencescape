# frozen_string_literal: true
class SamplePrepQcTask < Task # rubocop:todo Style/Documentation
  def partial
    'sample_prep_qc_batches'
  end

  def render_task(workflows_controller, params, _user)
    super
    workflows_controller.render_sample_prep_qc_task(self, params)
  end

  def do_task(workflows_controller, params, _user)
    workflows_controller.do_sample_prep_qc_task(self, params)
  end
end
