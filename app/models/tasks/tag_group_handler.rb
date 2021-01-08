module Tasks::TagGroupHandler # rubocop:todo Style/Documentation
  def render_tag_groups_task(_task, _params)
    @tag_groups = TagGroup.visible.all
  end
end
