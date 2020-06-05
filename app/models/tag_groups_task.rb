class TagGroupsTask < Task
  def partial
    'tag_groups_batches'
  end

  def render_task(workflow, params)
    super
    workflow.render_tag_groups_task(self, params)
  end

  def do_task(_workflow, _params)
    true
  end
end
