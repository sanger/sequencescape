class PrepKitBarcodeTask < Task # rubocop:todo Style/Documentation
  def partial
    'prep_kit_barcode_batches'
  end

  def render_task(workflows_controller, params, _user)
    super
    workflows_controller.render_prep_kit_barcode_task(self, params)
  end

  def included_for_render_task
    [:pipeline]
  end

  def included_for_do_task
    [:pipeline, { requests: :target_asset }]
  end

  def do_task(workflows_controller, params, _user)
    workflows_controller.do_prep_kit_barcode_task(self, params)
  end
end
