module Tasks::AttachInfiniumBarcodeHandler
  def render_attach_infinium_barcode_task(task, params)
    @studies = @batch.studies
  end

  def do_attach_infinium_barcode_task(task, params)
    barcodes = params[:barcodes]
    barcodes.each do |plate_id,barcode|
      next if barcode.blank?
      plate = Plate.find_by_id(plate_id)
      return false if plate.nil?
      # TODO[xxx]: validation of the infinium barcode should be in Plate::Metadata class
      return false unless plate.valid_infinium_barcode?(barcode)
      plate.infinium_barcode = barcode
    end
    true
  end

end
