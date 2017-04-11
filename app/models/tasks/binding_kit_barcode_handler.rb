# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

module Tasks::BindingKitBarcodeHandler
  def render_binding_kit_barcode_task(task, params)
  end

  def do_binding_kit_barcode_task(task, params)
    barcode = params[:binding_kit_barcode]
    if barcode.blank?
      flash[:error] = 'Please enter a Kit Barcode'
      return false
    end

    requests = task.find_batch_requests(params[:batch_id])
    ActiveRecord::Base.transaction do
      requests.each do |request|
        request.asset.pac_bio_library_tube_metadata.update_attributes!(binding_kit_barcode: barcode)
      end
    end

    true
  end
end
