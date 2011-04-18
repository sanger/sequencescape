class <%= singular_name.camelize %>Task < Task
  class <%= singular_name.camelize %>Data < Task::RenderElement
    def initialize(request)
      super(request)
    end
  end

  def create_render_element(request)
    request.asset && <%= singular_name.camelize %>Data.new(request)
  end

  def partial
    "<%= singular_name %>_batches"
  end

  def render_task(workflow, params)
    workflow.render_<%= singular_name %>_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_<%= singular_name %>_task(self, params)
  end

end