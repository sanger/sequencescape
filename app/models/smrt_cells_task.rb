class SmrtCellsTask < Task
  class SmrtCellsData < Task::RenderElement
    def initialize(request)
      super(request)
    end
  end

  def create_render_element(request)
    request.asset && SmrtCellsData.new(request)
  end

  def partial
    "smrt_cells_batches"
  end

  def render_task(workflow, params)
    super
    workflow.render_smrt_cells_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_smrt_cells_task(self, params)
  end


end
