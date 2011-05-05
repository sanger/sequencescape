class ReferenceSequenceTask < Task
  class ReferenceSequenceData < Task::RenderElement
    def initialize(request)
      super(request)
    end
  end

  def create_render_element(request)
    request.asset && ReferenceSequenceData.new(request)
  end

  def partial
    "reference_sequence_batches"
  end

  def render_task(workflow, params)
    super
    workflow.render_reference_sequence_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_reference_sequence_task(self, params)
  end

end
