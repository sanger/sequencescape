module Tasks::PrepKitBarcodeHandler
  def render_prep_kit_barcode_task(task, params)
  end

  def do_prep_kit_barcode_task(_task, params)
    barcode = params[:prep_kit_barcode].strip
    if barcode.blank?
      flash[:error] = 'Please enter a Kit Barcode'
      return false
    end

    requests = @batch.requests
    ActiveRecord::Base.transaction do
      requests.each do |request|
        request.target_asset.labware.pac_bio_library_tube_metadata.update!(prep_kit_barcode: barcode)
      end
    end

    true
  end
end
