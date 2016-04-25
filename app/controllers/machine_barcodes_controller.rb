#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

class MachineBarcodesController < ApplicationController

  def show
    asset = Asset.with_machine_barcode(params[:id]).first
    summary = asset.present? ? asset.summary_hash : {}
    status = asset.present? ? 200 : 404
    respond_to do |format|
      format.json { render :json => summary, :status => status }
    end
  end
end
