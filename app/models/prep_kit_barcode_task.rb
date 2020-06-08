class PrepKitBarcodeTask < Task
  def partial
    'prep_kit_barcode_batches'
  end

  def render_task(workflow, params)
    super
    workflow.render_prep_kit_barcode_task(self, params)
  end

  def included_for_render_task
    [:pipeline]
  end

  def included_for_do_task
    [:pipeline, { requests: :target_asset }]
  end

  def do_task(workflow, params)
    workflow.do_prep_kit_barcode_task(self, params)
  end
end
