# A {Task} used in {GenotypingPipeline Illumina Genotyping pipelines}
# Assigns an Infinium barcode to each of the plate ids supplied in params[:barcodes]
# This code isn't an entirely accurate representation of what goes on in the lab, as in reality the
# infinium barcode is a property of a child of the plate.
#
# @note At time of writing (3/4/2019) this is used in:
#   "Genotyping"
#
# @see Tasks::AttachInfiniumBarcodeHandlerfor behaviour included in the {WorkflowsController}
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
    'attach_infinium_barcode_batches'
  end

  def render_task(workflow, params)
    super
    workflow.render_attach_infinium_barcode_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_attach_infinium_barcode_task(self, params)
  end
end
