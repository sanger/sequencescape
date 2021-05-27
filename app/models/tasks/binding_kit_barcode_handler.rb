# Handles the behaviour of {BindingKitBarcodeTask} and included in {WorkflowsController}
# {include:BindingKitBarcodeTask}
module Tasks::BindingKitBarcodeHandler
  def render_binding_kit_barcode_task(task, params); end

  def do_binding_kit_barcode_task(task, params)
    barcode = params[:binding_kit_barcode]
    if barcode.blank?
      flash[:error] = 'Please enter a Kit Barcode'
      return false
    end

    requests = task.find_batch_requests(params[:batch_id])
    ActiveRecord::Base.transaction do
      requests.each { |request| request.pac_bio_library_tube_metadata.update!(binding_kit_barcode: barcode) }
    end

    true
  end
end
