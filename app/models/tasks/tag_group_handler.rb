module Tasks::TagGroupHandler
  def render_tag_groups_task(task, params)
    @tag_groups = TagGroup.all :conditions => {:visible => true}
  end
end