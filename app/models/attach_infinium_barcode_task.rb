class AttachInfiniumBarcodeTask < Task

  class AttachInfiniumBarcodeData < Task::RenderElement
    def initialize(request)
      super(request)
    end
  end

  def create_render_element(request)
    request.asset && AssignTagsData.new(request)
  end

  def partial
    "attach_infinium_barcode_batches"
  end

  def render_task(workflow, params)
    super
    workflow.render_attach_infinium_barcode_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_attach_infinium_barcode_task(self, params)
  end

end
