#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
module Tasks::PrepKitBarcodeHandler
  def render_prep_kit_barcode_task(task, params)
  end

  def do_prep_kit_barcode_task(task, params)
    barcode = params[:prep_kit_barcode]
    if barcode.blank?
      flash[:error] = "Please enter a Kit Barcode"
      return false
    end

    requests = task.find_batch_requests(params[:batch_id])
    ActiveRecord::Base.transaction do
      requests.each do |request|
        request.target_asset.pac_bio_library_tube_metadata.update_attributes!(:prep_kit_barcode => barcode)
      end
    end

    true
  end
end
