# A {Task} used in {PacBioSequencingPipeline}
# Assigns a binding kit barcode to the {PacBioLibraryTube}
#
# @note At time of writing (3/4/2019) this is used in:
#   "PacBio Sequencing"
#
# @see Tasks::BindingKitBarcodeHandler for behaviour included in the {WorkflowsController}
class BindingKitBarcodeTask < Task
  def partial
    'binding_kit_barcode_batches'
  end

  def render_task(workflows_controller, params, _user)
    super
    workflows_controller.render_binding_kit_barcode_task(self, params)
  end

  def do_task(workflows_controller, params, _user)
    workflows_controller.do_binding_kit_barcode_task(self, params)
  end
end
