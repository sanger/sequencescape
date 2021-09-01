class TagGroupsTask < Task # rubocop:todo Style/Documentation
  def partial
    'tag_groups_batches'
  end

  def render_task(workflow, params, _user)
    super
    workflow.render_tag_groups_task(self, params)
  end

  def do_task(_workflow, _params, _user)
    true
  end
end
