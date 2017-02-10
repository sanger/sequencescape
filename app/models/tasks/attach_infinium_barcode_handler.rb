# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

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
      # TODO[xxx]: validation of the infinium barcode should be in Plate::Metadata class
      return false unless plate.valid_infinium_barcode?(barcode)
      plate.infinium_barcode = barcode
    end
    true
  end
end
