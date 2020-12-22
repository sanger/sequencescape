class SetDescriptorsTask < Task # rubocop:todo Style/Documentation
  def render_task(workflows_controller, params)
    super
    workflows_controller.render_set_descriptors_task(self, params)
  end

  def do_task(workflows_controller, params)
    workflows_controller.do_set_descriptors_task(self, params)
  end
end
