
class MachineBarcodesController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!

  def show
    asset = Asset.with_barcode(params[:id]).first
    summary = asset.present? ? asset.summary_hash : {}
    status = asset.present? ? 200 : 404
    respond_to do |format|
      format.json { render json: summary, status: status }
    end
  end
end
