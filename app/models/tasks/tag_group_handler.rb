module Tasks::TagGroupHandler
  def render_tag_groups_task(task, params)
    @tag_groups = TagGroup.visible.all
  end
end