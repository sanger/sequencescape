class TagGroupsTask < Task

  class TagGroupsData < Task::RenderElement
    alias_attribute :well, :asset
    def initialize(request)
      super(request)
    end
  end

  def create_render_element(request)
    request.asset && TagGroupsData.new(request)
  end

  def partial
    "tag_groups_batches"
  end

  def render_task(workflow, params)
    super
    workflow.render_tag_groups_task(self, params)
  end

  def do_task(workflow, params)
    true
  end

end
