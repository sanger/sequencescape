module Tasks::TagGroupHandler
  def render_tag_groups_task(_task, _params)
    @tag_groups = TagGroup.visible.all
  end
end
