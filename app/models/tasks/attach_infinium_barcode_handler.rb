module Tasks::AttachInfiniumBarcodeHandler
  def render_attach_infinium_barcode_task(_task, _params)
    @studies = @batch.studies
  end

  def do_attach_infinium_barcode_task(_task, params)
    barcodes = params[:barcodes]
    barcodes.each do |plate_id, barcode|
      next if barcode.blank?

      plate = Plate.find_by(id: plate_id)
      return false if plate.nil?

      plate.infinium_barcode = barcode
      return false unless plate.save
    end
    true
  end
end
