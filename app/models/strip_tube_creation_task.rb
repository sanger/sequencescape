class StripTubeCreationTask < Task

  belongs_to :purpose

  def render_task(workflow, params)
    workflow.render_strip_tube_creation_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_strip_tube_creation_task(self, params)
  end

  def partial
    self.class.to_s.underscore.chomp('_task')
  end

end
