class AssignTubesToWellsTask < Task
  class AssignTubesToWellsData < Task::RenderElement
    def initialize(request)
      super(request)
    end
  end

  def create_render_element(request)
    request.asset && AssignTubesToWellsData.new(request)
  end

  def partial
    "assign_tubes_to_wells_batches"
  end

  def render_task(workflow, params)
    super
    workflow.render_assign_tubes_to_wells_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_assign_tubes_to_wells_task(self, params)
  end


end
